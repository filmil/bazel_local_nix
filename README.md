<!-- SPDX-License-Identifier: Apache-2.0 -->

# rules_nix (bazel_local_nix) [![Test status](https://github.com/filmil/bazel_local_nix/actions/workflows/test.yml/badge.svg)](https://github.com/filmil/bazel_local_nix/actions/workflows/test.yml) [![Publish status](https://github.com/filmil/bazel_local_nix/actions/workflows/publish.yml/badge.svg)](https://github.com/filmil/bazel_local_nix/actions/workflows/publish.yml) [![Publish BCR status](https://github.com/filmil/bazel_local_nix/actions/workflows/publish-bcr.yml/badge.svg)](https://github.com/filmil/bazel_local_nix/actions/workflows/publish-bcr.yml) [![Tag and Release status](https://github.com/filmil/bazel_local_nix/actions/workflows/tag-and-release.yml/badge.svg)](https://github.com/filmil/bazel_local_nix/actions/workflows/tag-and-release.yml)

Bazel rules that make Nix packages available inside a Bazel workspace
**without a host-level Nix installation and without `nix-portable`**. They
bootstrap an ephemeral Nix from the official binary release, run it
unprivileged inside a `bwrap` (bubblewrap) user namespace against a persistent
store, and expose the results as ordinary Bazel artifacts. The `bwrap` binary
itself is fetched as a pinned, statically-linked release during bootstrap, so
**no host-provided `bwrap` is required** — only permission to create
unprivileged user namespaces.

> **Note on history.** Earlier versions of this repository shimmed *all* of
> Bazel through a `nix-portable` `nix-shell` via an injected `tools/bazel`
> wrapper. That approach has been **removed** and replaced by the rule set
> described here. See the `BREAKING CHANGE` note in the git history.

## Requirements

- Linux `x86_64`.
- Permission to create **unprivileged user namespaces** (`bwrap` itself is
  bundled — fetched as a pinned static binary during bootstrap — so it does not
  need to be installed on the host).
- `bash`, `tar`, `xz`, `cp`, `flock`, and coreutils.
- Network egress to `https://releases.nixos.org` (bootstrap) and
  `https://cache.nixos.org` (substitutes).
- Bazel with bzlmod (`.bazelversion` pins the version).

## Usage

To use these rules, first configure your `.bazelrc` to use the custom registry:

```
common --registry=https://raw.githubusercontent.com/filmil/bazel-registry/main
common --registry=https://bcr.bazel.build
```

In `MODULE.bazel`:

```starlark
bazel_dep(name = "rules_nix", version = "0.0.1")

nix_bootstrap = use_repo_rule("@rules_nix//:nix_bootstrap.bzl", "nix_bootstrap")
nix_bootstrap(name = "nix_bootstrap")
```

In a `BUILD` file:

```starlark
load("@rules_nix//:nix_rules.bzl", "nix_package", "nix_toolchain")

# Build a Nix installable into a relocatable bundle.
nix_package(
    name = "hello_pack",
    installable = "github:NixOS/nixpkgs/<rev>#hello",
    tags = ["requires-network"],
)

# Extract the bundle into a directory tree.
nix_toolchain(
    name = "hello_tool",
    bundle = ":hello_pack",
)

# Run the bundled binary. The extracted bin/<tool> is a relocatable shim that
# re-execs the real binary under bwrap with the bundle's store bound at
# /nix/store, so no host /nix is required.
genrule(
    name = "run_hello",
    srcs = [":hello_tool"],
    outs = ["hello_output.txt"],
    cmd = "$(location :hello_tool)/bin/hello > $@",
    tags = ["no-sandbox", "local"],
)
```

See the generated rule reference for details:
- [`nix_rules.md`](nix_rules.md) — primary build rules (`nix_package`, `nix_toolchain`).
- [`nix_bootstrap.md`](nix_bootstrap.md) — repository bootstrap rule.
- [`nix_cc.md`](nix_cc.md) — C/C++ toolchain rules and configuration.
- [`nix_gnat.md`](nix_gnat.md) — Ada (GNAT) toolchain rules and configuration.
- [`elf_bundle.md`](elf_bundle.md) — creating self-extracting bundles.
- [`extensions.md`](extensions.md) — bzlmod extensions for toolchain configuration.

### Nix-backed C/C++ toolchain

A module extension turns a nixpkgs compiler into a registered Bazel
`cc_toolchain` (the rules_nix analog of `tweag/rules_nixpkgs`). In
`MODULE.bazel`:

```starlark
bazel_dep(name = "rules_cc", version = "0.2.17")

nix_cc = use_extension("@rules_nix//:extensions.bzl", "nix_cc")
nix_cc.configure(
    attribute = "gcc",
    nixpkgs = "github:NixOS/nixpkgs/<rev>",
)
use_repo(nix_cc, "nix_cc_toolchain")
register_toolchains("@nix_cc_toolchain//:toolchain")
```

Ordinary `cc_binary` / `cc_library` targets are then compiled by the Nix
compiler. The compiler runs inside `bwrap` (real filesystem visible, the
toolchain's closure overlaid at `/nix/store`), so **cc actions must use the
local spawn strategy** — add to the consuming workspace's `.bazelrc`:

```
build --spawn_strategy=local
```

The produced binaries link against `/nix/store`, so they run on a host with no
`/nix` only when executed under `bwrap` with the toolchain store bound at
`/nix/store` (the `with-nix-clang` integration module shows this).

## How it works

- **`nix_bootstrap`** (repository rule) downloads a pinned, checksummed Nix
  release plus a pinned, statically-linked `bwrap` binary, unpacks them, and
  materializes the runtime wrapper `nix_wrapper.sh` and the relocatable run-shim
  from `nix_wrapper.sh.tpl` / `nix_run_shim.sh`. Every wrapper and shim execs
  the bundled `bwrap`, never a host one.
- **`nix_wrapper.sh`** runs an arbitrary `nix` subcommand inside `bwrap`
  against a persistent, single-user store under
  `<output_user_root>/rules_nix_store` (override with `RULES_NIX_CACHE`). The
  store is seeded once from the release and registered with
  `nix-store --load-db`; substitutes come from `cache.nixos.org`. No daemon and
  no root are required.
- **`nix_package`** invokes the wrapper to `nix build` an installable, then
  tars its runtime closure (plus relocatable `bin/` shims) into
  `<name>.tar.gz`. The action runs `local` + `no-sandbox` + `requires-network`
  because it shares the persistent store and needs substitutes.
- **`nix_toolchain`** extracts a bundle into `<name>_extracted/`.

## Reproducibility

Pin the `nixpkgs` revision in `installable` (a flake `github:...#attr` with a
commit, or a pinned tarball). Unpinned references are non-deterministic and
should not be used in released rules. With a pinned revision and the binary
cache enabled, `nix_package` downloads rather than building from source.

## Integration examples

- `integration/partially-installed` — bundles `hello` and runs it.
- `integration/with-nix-clang` — compiles `hello.cc` with a Nix-backed Bazel
  `cc_toolchain` configured in `MODULE.bazel`.

## Limitations

- Linux `x86_64` only; remote execution is unsupported (the store is mutable,
  shared, and accessed `local`/`no-sandbox`).
- The first build pays a one-time cost (store seeding + substitute downloads);
  later builds reuse the cache.
- Targets using the Nix-backed `cc_toolchain` must run cc actions with the
  local spawn strategy (the compiler runs under `bwrap`, which cannot nest
  inside Bazel's sandbox), and the binaries they produce reference
  `/nix/store`.
