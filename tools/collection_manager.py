#!/usr/bin/env python3
"""Manage versioned CX package collections described as YAML."""

from __future__ import annotations

import argparse
import functools
import re
import shutil
import subprocess
import sys
from dataclasses import dataclass
from pathlib import Path
from typing import Any, Callable, Iterable

import yaml


NAME_RE = re.compile(r"^[A-Za-z0-9][A-Za-z0-9._-]*$")
VERSION_RE = re.compile(r"^(0|[1-9]\d*)\.(0|[1-9]\d*)\.(0|[1-9]\d*)(?:-([0-9A-Za-z.-]+))?$")


class CollectionError(ValueError):
    """Raised for invalid collections or resolution/install failures."""


@functools.total_ordering
@dataclass(frozen=True)
class Version:
    major: int
    minor: int
    patch: int
    prerelease: str = ""

    @classmethod
    def parse(cls, value: str) -> "Version":
        match = VERSION_RE.fullmatch(value)
        if not match:
            raise CollectionError(f"invalid semantic version: {value!r}")
        return cls(int(match[1]), int(match[2]), int(match[3]), match[4] or "")

    def __lt__(self, other: object) -> bool:
        if not isinstance(other, Version):
            return NotImplemented
        core_self = (self.major, self.minor, self.patch)
        core_other = (other.major, other.minor, other.patch)
        if core_self != core_other:
            return core_self < core_other
        if self.prerelease == other.prerelease:
            return False
        if not self.prerelease:
            return False
        if not other.prerelease:
            return True

        left = self.prerelease.split(".")
        right = other.prerelease.split(".")
        for left_id, right_id in zip(left, right):
            if left_id == right_id:
                continue
            left_numeric = left_id.isdigit()
            right_numeric = right_id.isdigit()
            if left_numeric and right_numeric:
                return int(left_id) < int(right_id)
            if left_numeric != right_numeric:
                return left_numeric
            return left_id < right_id
        return len(left) < len(right)


@dataclass(frozen=True)
class Dependency:
    name: str
    constraint: str = ""

    @classmethod
    def parse(cls, raw: str) -> "Dependency":
        if not isinstance(raw, str) or not raw.strip():
            raise CollectionError("collection dependencies must be non-empty strings")
        text = raw.strip()
        if "@" not in text:
            name, constraint = text, ""
        else:
            name, constraint = text.split("@", 1)
        if not NAME_RE.fullmatch(name):
            raise CollectionError(f"invalid collection dependency name: {name!r}")
        return cls(name, constraint.strip())


@dataclass(frozen=True)
class Collection:
    name: str
    version: Version
    description: str
    packages: tuple[str, ...]
    dependencies: tuple[Dependency, ...]
    configurations: dict[str, Any]
    source: Path

    @property
    def version_string(self) -> str:
        value = f"{self.version.major}.{self.version.minor}.{self.version.patch}"
        return f"{value}-{self.version.prerelease}" if self.version.prerelease else value


def _version_satisfies(version: Version, constraint: str) -> bool:
    if not constraint:
        return True
    for token in (piece.strip() for piece in constraint.split(",")):
        if not token:
            continue
        match = re.fullmatch(r"(>=|<=|==|=|>|<)?\s*(\d+\.\d+\.\d+(?:-[0-9A-Za-z.-]+)?)", token)
        if not match:
            raise CollectionError(f"unsupported version constraint: {constraint!r}")
        op = match[1] or "=="
        wanted = Version.parse(match[2])
        if op in ("=", "==") and version != wanted:
            return False
        if op == ">=" and version < wanted:
            return False
        if op == "<=" and version > wanted:
            return False
        if op == ">" and version <= wanted:
            return False
        if op == "<" and version >= wanted:
            return False
    return True


def _parse_package(raw: Any) -> str:
    if not isinstance(raw, str) or not raw.strip():
        raise CollectionError("packages must be non-empty strings")
    package = raw.strip()
    if any(ch.isspace() for ch in package):
        raise CollectionError(f"package entries may not contain whitespace: {package!r}")
    if package.startswith("-") or any(ch in package for ch in ";|&`$\n\r"):
        raise CollectionError(f"unsafe package entry: {package!r}")
    if package.count("@") > 1:
        raise CollectionError(f"invalid versioned package: {package!r}")
    if "@" in package:
        name, version = package.split("@", 1)
        if not name or not version:
            raise CollectionError(f"invalid versioned package: {package!r}")
    return package


def load_collection(path: Path) -> Collection:
    try:
        raw = yaml.safe_load(path.read_text(encoding="utf-8"))
    except (OSError, UnicodeError, yaml.YAMLError) as exc:
        raise CollectionError(f"cannot read collection {path}: {exc}") from exc
    if not isinstance(raw, dict):
        raise CollectionError("collection document must be a YAML mapping")

    allowed = {"collection", "version", "description", "packages", "dependencies", "configurations"}
    unknown = sorted(set(raw) - allowed)
    if unknown:
        raise CollectionError(f"unknown collection fields: {', '.join(unknown)}")

    name = raw.get("collection")
    if not isinstance(name, str) or not NAME_RE.fullmatch(name):
        raise CollectionError("collection must be a simple non-empty name")
    version_raw = raw.get("version")
    if not isinstance(version_raw, str):
        raise CollectionError("version must be a quoted semantic version string")
    version = Version.parse(version_raw)

    description = raw.get("description", "")
    if not isinstance(description, str):
        raise CollectionError("description must be a string")

    raw_packages = raw.get("packages")
    if not isinstance(raw_packages, list) or not raw_packages:
        raise CollectionError("packages must be a non-empty list")
    packages = tuple(_parse_package(item) for item in raw_packages)
    if len(set(packages)) != len(packages):
        raise CollectionError("packages must not contain duplicates")

    raw_dependencies = raw.get("dependencies", [])
    if not isinstance(raw_dependencies, list):
        raise CollectionError("dependencies must be a list")
    dependencies = tuple(Dependency.parse(item) for item in raw_dependencies)
    dep_names = [dep.name for dep in dependencies]
    if len(set(dep_names)) != len(dep_names):
        raise CollectionError("collection dependencies must not contain duplicates")
    if name in dep_names:
        raise CollectionError("a collection cannot depend on itself")

    configurations = raw.get("configurations", {})
    if configurations is None:
        configurations = {}
    if not isinstance(configurations, dict):
        raise CollectionError("configurations must be a mapping")

    return Collection(name, version, description, packages, dependencies, configurations, path)


class CollectionStore:
    """Filesystem registry storing one YAML file per collection version."""

    def __init__(self, root: Path):
        self.root = Path(root)

    def _path(self, name: str, version: Version) -> Path:
        return self.root / name / f"{version.major}.{version.minor}.{version.patch}{('-' + version.prerelease) if version.prerelease else ''}.yaml"

    def import_file(self, source: Path, *, replace: bool = False) -> Collection:
        collection = load_collection(source)
        target = self._path(collection.name, collection.version)
        if target.exists() and not replace:
            raise CollectionError(f"collection already imported: {collection.name}@{collection.version_string}")
        target.parent.mkdir(parents=True, exist_ok=True)
        shutil.copyfile(source, target)
        return load_collection(target)

    def versions(self, name: str) -> list[Collection]:
        directory = self.root / name
        if not directory.is_dir():
            return []
        result: list[Collection] = []
        for path in directory.glob("*.yaml"):
            result.append(load_collection(path))
        return sorted(result, key=lambda item: item.version, reverse=True)

    def resolve(self, name: str, constraint: str = "") -> Collection:
        if not NAME_RE.fullmatch(name):
            raise CollectionError(f"invalid collection name: {name!r}")
        for collection in self.versions(name):
            if _version_satisfies(collection.version, constraint):
                return collection
        suffix = f" matching {constraint}" if constraint else ""
        raise CollectionError(f"collection not found: {name}{suffix}")

    def list(self) -> list[Collection]:
        if not self.root.is_dir():
            return []
        latest: list[Collection] = []
        for child in sorted(self.root.iterdir()):
            if child.is_dir():
                versions = self.versions(child.name)
                if versions:
                    latest.append(versions[0])
        return latest

    def export(self, name: str, destination: Path, constraint: str = "") -> Collection:
        collection = self.resolve(name, constraint)
        destination = Path(destination)
        destination.parent.mkdir(parents=True, exist_ok=True)
        shutil.copyfile(collection.source, destination)
        return collection

    def plan(self, name: str, constraint: str = "") -> list[Collection]:
        ordered: list[Collection] = []
        visited: set[tuple[str, Version]] = set()
        stack: list[str] = []

        def visit(dep_name: str, dep_constraint: str) -> None:
            if dep_name in stack:
                cycle = " -> ".join([*stack, dep_name])
                raise CollectionError(f"collection dependency cycle: {cycle}")
            collection = self.resolve(dep_name, dep_constraint)
            key = (collection.name, collection.version)
            if key in visited:
                return
            stack.append(dep_name)
            for dependency in collection.dependencies:
                visit(dependency.name, dependency.constraint)
            stack.pop()
            visited.add(key)
            ordered.append(collection)

        visit(name, constraint)
        return ordered


def packages_for_plan(plan: Iterable[Collection]) -> list[str]:
    seen: dict[str, str | None] = {}
    result: list[str] = []
    for collection in plan:
        for package in collection.packages:
            if "@" in package:
                package_name, requested_version = package.split("@", 1)
            else:
                package_name, requested_version = package, None

            if package_name in seen:
                if seen[package_name] != requested_version:
                    previous = f"{package_name}@{seen[package_name]}" if seen[package_name] else package_name
                    raise CollectionError(
                        f"conflicting package requirements: {previous!r} and {package!r}"
                    )
                continue

            seen[package_name] = requested_version
            result.append(package)
    return result


def apt_package_arg(package: str) -> str:
    """Translate collection name@version notation to apt's name=version form."""
    if "@" not in package:
        return package
    name, version = package.rsplit("@", 1)
    if not name or not version:
        raise CollectionError(f"invalid versioned package: {package!r}")
    return f"{name}={version}"


def install_collection(
    store: CollectionStore,
    name: str,
    constraint: str = "",
    *,
    assume_yes: bool = False,
    runner: Callable[..., Any] = subprocess.run,
) -> list[str]:
    plan = store.plan(name, constraint)
    packages = packages_for_plan(plan)
    command = ["apt-get", "install"]
    if assume_yes:
        command.append("-y")
    command.extend(apt_package_arg(package) for package in packages)
    try:
        runner(command, check=True)
    except (OSError, subprocess.CalledProcessError) as exc:
        raise CollectionError(f"package installation failed: {exc}") from exc
    return packages


def _target(text: str) -> tuple[str, str]:
    if "@" not in text:
        return text, ""
    name, constraint = text.split("@", 1)
    return name, constraint


def _build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(description="Manage versioned CX package collections")
    parser.add_argument("--store", type=Path, default=Path.home() / ".local/share/cx/collections")
    sub = parser.add_subparsers(dest="command", required=True)

    validate = sub.add_parser("validate", help="validate a collection YAML file")
    validate.add_argument("file", type=Path)

    imp = sub.add_parser("import", help="import a collection into the local registry")
    imp.add_argument("file", type=Path)
    imp.add_argument("--replace", action="store_true")

    exp = sub.add_parser("export", help="export a collection YAML file for sharing")
    exp.add_argument("target", help="NAME or NAME@VERSION/CONSTRAINT")
    exp.add_argument("output", type=Path)

    sub.add_parser("list", help="list the latest version of imported collections")

    show = sub.add_parser("show", help="show a resolved collection")
    show.add_argument("target")

    plan = sub.add_parser("plan", help="resolve collection dependencies and package order")
    plan.add_argument("target")

    install = sub.add_parser("install", help="validate, resolve and install a collection")
    install.add_argument("target")
    install.add_argument("-y", "--yes", action="store_true", help="pass -y to apt-get")
    return parser


def main(argv: list[str] | None = None) -> int:
    args = _build_parser().parse_args(argv)
    store = CollectionStore(args.store)
    try:
        if args.command == "validate":
            collection = load_collection(args.file)
            print(f"valid: {collection.name}@{collection.version_string}")
        elif args.command == "import":
            collection = store.import_file(args.file, replace=args.replace)
            print(f"imported: {collection.name}@{collection.version_string}")
        elif args.command == "export":
            name, constraint = _target(args.target)
            collection = store.export(name, args.output, constraint)
            print(f"exported: {collection.name}@{collection.version_string} -> {args.output}")
        elif args.command == "list":
            for collection in store.list():
                print(f"{collection.name}@{collection.version_string}\t{collection.description}")
        elif args.command == "show":
            name, constraint = _target(args.target)
            collection = store.resolve(name, constraint)
            print(collection.source.read_text(encoding="utf-8"), end="")
        elif args.command == "plan":
            name, constraint = _target(args.target)
            plan = store.plan(name, constraint)
            for collection in plan:
                print(f"{collection.name}@{collection.version_string}")
            print("packages: " + " ".join(packages_for_plan(plan)))
        elif args.command == "install":
            name, constraint = _target(args.target)
            packages = install_collection(store, name, constraint, assume_yes=args.yes)
            print(f"installed {len(packages)} packages from {name}")
        return 0
    except CollectionError as exc:
        print(f"error: {exc}", file=sys.stderr)
        return 2


if __name__ == "__main__":
    raise SystemExit(main())
