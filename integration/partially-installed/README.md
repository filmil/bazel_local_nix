<!-- SPDX-License-Identifier: Apache-2.0 -->

# Integration: bundle and run a Nix package

A standalone Bazel module that consumes `rules_nix` via `local_path_override`
and exercises the core flow:

- `nix_package` bundles `hello` from a pinned nixpkgs into a `.tar.gz`.
- `nix_toolchain` extracts the bundle.
- a `genrule` runs the bundled `hello` through its relocatable run-shim.

The targets are tagged `manual` (and `requires-network` / `no-sandbox` /
`local`) because they reach `cache.nixos.org` and run Nix under `bwrap`. Run
them explicitly:

```sh
bazel build //:test_hello
cat bazel-bin/hello_out.txt   # -> Hello world!
```
