import contextlib
import importlib.util
import io
import subprocess
import sys
import tempfile
import unittest
from pathlib import Path

MODULE_PATH = Path(__file__).parents[1] / "tools" / "collection_manager.py"
spec = importlib.util.spec_from_file_location("collection_manager", MODULE_PATH)
cm = importlib.util.module_from_spec(spec)
assert spec and spec.loader
sys.modules[spec.name] = cm
spec.loader.exec_module(cm)


def write_collection(root: Path, text: str, name: str = "collection.yaml") -> Path:
    path = root / name
    path.write_text(text, encoding="utf-8")
    return path


class CollectionManagerTests(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        self.root = Path(self.tmp.name)
        self.store = cm.CollectionStore(self.root / "store")

    def tearDown(self):
        self.tmp.cleanup()

    def basic(self, name="base", version="1.0.0", extra=""):
        return write_collection(self.root, f'''collection: {name}\nversion: "{version}"\ndescription: test\npackages:\n  - curl\n{extra}''', f"{name}-{version}.yaml")

    def test_load_valid_collection(self):
        item = cm.load_collection(self.basic())
        self.assertEqual(item.name, "base")
        self.assertEqual(item.version_string, "1.0.0")
        self.assertEqual(item.packages, ("curl",))

    def test_rejects_bad_documents_and_fields(self):
        bad = [
            "- nope\n",
            'collection: "bad name"\nversion: "1.0.0"\npackages: [curl]\n',
            'collection: ok\nversion: 1.0\npackages: [curl]\n',
            'collection: ok\nversion: "1.0.0"\npackages: []\n',
            'collection: ok\nversion: "1.0.0"\npackages: ["bad;rm"]\n',
            'collection: ok\nversion: "1.0.0"\npackages: ["foo@"]\n',
            'collection: ok\nversion: "1.0.0"\npackages: ["@1.0"]\n',
            'collection: ok\nversion: "1.0.0"\npackages: ["foo@bar@1.0"]\n',
            'collection: ok\nversion: "1.0.0"\npackages: [curl, curl]\n',
            'collection: ok\nversion: "1.0.0"\npackages: [curl]\nwat: 1\n',
            'collection: ok\nversion: "1.0.0"\npackages: [curl]\nconfigurations: []\n',
        ]
        for index, text in enumerate(bad):
            with self.subTest(index=index):
                with self.assertRaises(cm.CollectionError):
                    cm.load_collection(write_collection(self.root, text, f"bad-{index}.yaml"))

    def test_dependencies_validate(self):
        path = write_collection(self.root, 'collection: app\nversion: "1.0.0"\npackages: [curl]\ndependencies: ["base@>=1.0.0", "extra"]\n')
        deps = cm.load_collection(path).dependencies
        self.assertEqual((deps[0].name, deps[0].constraint), ("base", ">=1.0.0"))
        for text in [
            'collection: app\nversion: "1.0.0"\npackages: [curl]\ndependencies: app\n',
            'collection: app\nversion: "1.0.0"\npackages: [curl]\ndependencies: [app]\n',
            'collection: app\nversion: "1.0.0"\npackages: [curl]\ndependencies: [base, base]\n',
        ]:
            with self.assertRaises(cm.CollectionError):
                cm.load_collection(write_collection(self.root, text, "baddep.yaml"))

    def test_import_list_resolve_export_and_replace(self):
        source_v1 = self.basic("tool", "1.0.0")
        source_v2 = self.basic("tool", "2.0.0")
        v1 = self.store.import_file(source_v1)
        v2 = self.store.import_file(source_v2)
        self.assertEqual(self.store.list()[0].version_string, "2.0.0")
        self.assertEqual(self.store.resolve("tool", ">=1.0.0,<2.0.0").version_string, "1.0.0")
        out = self.root / "shared" / "tool.yaml"
        chosen = self.store.export("tool", out, "2.0.0")
        self.assertEqual(chosen.version_string, "2.0.0")
        self.assertTrue(out.exists())
        with self.assertRaises(cm.CollectionError):
            self.store.import_file(v1.source)
        replaced = self.store.import_file(source_v1, replace=True)
        self.assertEqual(replaced.version_string, "1.0.0")

    def test_semver_orders_stable_and_prerelease_identifiers(self):
        versions = [
            cm.Version.parse("1.0.0"),
            cm.Version.parse("1.0.0-rc.2"),
            cm.Version.parse("1.0.0-rc.10"),
            cm.Version.parse("1.0.0-beta"),
        ]
        self.assertEqual(
            [f"{v.major}.{v.minor}.{v.patch}" + (f"-{v.prerelease}" if v.prerelease else "") for v in sorted(versions)],
            ["1.0.0-beta", "1.0.0-rc.2", "1.0.0-rc.10", "1.0.0"],
        )

    def test_resolve_prefers_stable_release_over_prerelease(self):
        self.store.import_file(self.basic("tool", "1.0.0-rc.2"))
        self.store.import_file(self.basic("tool", "1.0.0"))
        self.assertEqual(self.store.resolve("tool").version_string, "1.0.0")

    def test_resolve_errors(self):
        with self.assertRaises(cm.CollectionError):
            self.store.resolve("bad name")
        self.store.import_file(self.basic("tool", "1.0.0"))
        with self.assertRaises(cm.CollectionError):
            self.store.resolve("tool", ">=2.0.0")
        with self.assertRaises(cm.CollectionError):
            self.store.resolve("tool", "^1.0.0")

    def test_dependency_plan_orders_and_deduplicates_packages(self):
        self.store.import_file(write_collection(self.root, 'collection: base\nversion: "1.0.0"\npackages: [curl, git]\n', "base.yaml"))
        self.store.import_file(write_collection(self.root, 'collection: data\nversion: "2.0.0"\npackages: [git, python3]\ndependencies: ["base@>=1.0.0"]\n', "data.yaml"))
        plan = self.store.plan("data")
        self.assertEqual([x.name for x in plan], ["base", "data"])
        self.assertEqual(cm.packages_for_plan(plan), ["curl", "git", "python3"])

    def test_conflicting_package_versions_are_rejected(self):
        first = cm.Collection(
            "first", cm.Version.parse("1.0.0"), "", ("foo@1.0",), (), {}, Path("first.yaml")
        )
        second = cm.Collection(
            "second", cm.Version.parse("1.0.0"), "", ("foo@2.0",), (), {}, Path("second.yaml")
        )
        unpinned = cm.Collection(
            "unpinned", cm.Version.parse("1.0.0"), "", ("foo",), (), {}, Path("unpinned.yaml")
        )
        with self.assertRaisesRegex(cm.CollectionError, "conflicting package requirements"):
            cm.packages_for_plan([first, second])
        with self.assertRaisesRegex(cm.CollectionError, "conflicting package requirements"):
            cm.packages_for_plan([first, unpinned])

    def test_dependency_cycle_and_missing_dependency(self):
        self.store.import_file(write_collection(self.root, 'collection: a\nversion: "1.0.0"\npackages: [a]\ndependencies: [b]\n', "a.yaml"))
        self.store.import_file(write_collection(self.root, 'collection: b\nversion: "1.0.0"\npackages: [b]\ndependencies: [a]\n', "b.yaml"))
        with self.assertRaisesRegex(cm.CollectionError, "cycle"):
            self.store.plan("a")
        other = cm.CollectionStore(self.root / "other")
        other.import_file(write_collection(self.root, 'collection: c\nversion: "1.0.0"\npackages: [c]\ndependencies: [missing]\n', "c.yaml"))
        with self.assertRaisesRegex(cm.CollectionError, "not found"):
            other.plan("c")

    def test_install_uses_apt_and_version_translation(self):
        self.store.import_file(write_collection(self.root, 'collection: dev\nversion: "1.0.0"\npackages: ["python3@3.11", git]\n', "dev.yaml"))
        calls = []
        def runner(command, check):
            calls.append((command, check))
        packages = cm.install_collection(self.store, "dev", assume_yes=True, runner=runner)
        self.assertEqual(packages, ["python3@3.11", "git"])
        self.assertEqual(calls, [(["apt-get", "install", "-y", "python3=3.11", "git"], True)])

    def test_install_wraps_runner_failures(self):
        self.store.import_file(self.basic())
        def runner(*args, **kwargs):
            raise subprocess.CalledProcessError(1, args[0])
        with self.assertRaisesRegex(cm.CollectionError, "installation failed"):
            cm.install_collection(self.store, "base", runner=runner)

    def test_cli_validate_import_plan_export_list_show(self):
        source = self.basic()
        stdout = io.StringIO(); stderr = io.StringIO()
        with contextlib.redirect_stdout(stdout), contextlib.redirect_stderr(stderr):
            self.assertEqual(cm.main(["--store", str(self.store.root), "validate", str(source)]), 0)
            self.assertEqual(cm.main(["--store", str(self.store.root), "import", str(source)]), 0)
            self.assertEqual(cm.main(["--store", str(self.store.root), "list"]), 0)
            self.assertEqual(cm.main(["--store", str(self.store.root), "show", "base"]), 0)
            self.assertEqual(cm.main(["--store", str(self.store.root), "plan", "base"]), 0)
            self.assertEqual(cm.main(["--store", str(self.store.root), "export", "base", str(self.root / "export.yaml")]), 0)
        self.assertIn("valid: base@1.0.0", stdout.getvalue())
        self.assertTrue((self.root / "export.yaml").exists())

    def test_cli_reports_validation_error(self):
        path = write_collection(self.root, "not: valid\n", "invalid.yaml")
        stderr = io.StringIO()
        with contextlib.redirect_stderr(stderr):
            code = cm.main(["validate", str(path)])
        self.assertEqual(code, 2)
        self.assertIn("error:", stderr.getvalue())


if __name__ == "__main__":
    unittest.main()
