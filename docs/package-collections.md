# Package collections

Package collections are shareable YAML manifests for installing a related, versioned set of Debian packages. The manager validates every manifest before it mutates the system, resolves collection-to-collection dependencies in topological order, and installs each package once.

## Definition format

```yaml
collection: data-science-stack
version: "1.2.0"
description: Complete data science environment
packages:
  - python3
  - jupyter-notebook
  - python3-pandas
dependencies:
  - base-development@>=1.0.0,<2.0.0
configurations:
  jupyter:
    port: 8888
```

`collection` must be a simple name. `version` uses semantic `MAJOR.MINOR.PATCH`. `packages` is a non-empty list; package pins may use `name@version`, which is translated to APT's `name=version` form at install time. `dependencies` is optional and accepts `name`, exact versions, or comma-separated `>=`, `<=`, `>`, `<`, and `=`/`==` constraints. `configurations` is preserved as collection metadata for higher-level consumers; the package installer does not write arbitrary application configuration files.

## Use

```bash
# Validate a file before importing it
python3 tools/collection_manager.py validate collections/examples/base-development.yaml

# Import versions into the local collection registry
python3 tools/collection_manager.py import collections/examples/base-development.yaml
python3 tools/collection_manager.py import collections/examples/data-science-stack.yaml

# Inspect the dependency/install plan without changing the machine
python3 tools/collection_manager.py plan data-science-stack

# Install the resolved package set through apt-get
sudo python3 tools/collection_manager.py --store "$HOME/.local/share/cx/collections" install data-science-stack --yes

# Export the resolved version for sharing
python3 tools/collection_manager.py export 'data-science-stack@>=1.0.0,<2.0.0' ./data-science-stack.yaml
```

The default registry is `~/.local/share/cx/collections`. Override it with `--store PATH`, which also makes tests and CI fully unprivileged.

## Version and dependency behavior

When a dependency omits a version, the newest imported version is selected. A constraint selects the newest imported version satisfying all comma-separated comparisons. Circular dependencies, missing dependencies, unsafe package entries, duplicate packages/dependencies, unknown manifest fields, and invalid versions fail before `apt-get` is invoked.

## Tests

```bash
python3 -m unittest tests/test_collection_manager.py
coverage run --source=tools/collection_manager.py -m unittest tests/test_collection_manager.py
coverage report -m
```

The tests use temporary registries and an injected fake package executor, so they never invoke privileged package installation.
