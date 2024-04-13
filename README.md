# Fully hermetic bazel build with nix, without `/nix/store` [![Test status](https://github.com/filmil/bazel-nix-flakes/workflows/Test/badge.svg)](https://github.com/filmil/bazel-nix-flakes/workflows/Test/badge.svg)

An experiment in fully hermetic, but also self-installing [nix][nx] based
hermetic bazel build.

[nx]: https://nixos.org

The build rules at https://github.com/tweag/rules_nixpkgs allow bazel to bring
in dependencies from [nixpkgs][nxp]. But, it requires having a `/nix/store` on
your machine, which in turn means you need to have a pre-existing system-wide
nix installation.

[nxp]: https://github.com/NixOS/nixpkgs

This repository goes one step further: `bazel` will instantiate a bazel-specific
nix store and pull in the appropriate dependencies from nixpkgs. This means that
you will not need to install nix in order to use the packages from nixpkgs.

This example repo adds the dir `//tools` to an existing `rules_nixpkgs`
example, which makes a stand-alone and ephemeral nix installation in your bazel
cache, and prepares all dependencies for compilation.  It then builds a hello
world app.

1. install bazelisk, name it `bazel`
2. try: `bazel run :hello`

---

Original README.md below.
From https://github.com/tweag/rules_nixpkgs/tree/master/examples/flakes

---

# bazel-nix-flakes-example

The example is generating a local nixpkgs repository using the `flakes.lock` file already present on
[flakes](https://nixos.wiki/wiki/Flakes) projects.

## Requirements

The nix package manager should be installed with flakes support enabled.

## Running the example

The local nixpkgs repository can be used by explicitly specifying the generated toolchain.

``bash
nix-shell --run "bazel run --crosstool_top=@nixpkgs_config_cc//:toolchain :hello"
```
