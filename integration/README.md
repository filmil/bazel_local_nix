# Fully hermetic bazel build with nix, without `/nix/store` [![Test status](https://github.com/filmil/bazel_local_nix/workflows/Test/badge.svg)](https://github.com/filmil/bazel_local_nix/workflows/Test/badge.svg)

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

See also how this is used at: https://github.com/filmil/bazel-nix-flakes