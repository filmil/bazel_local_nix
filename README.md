# Hermetic, ephemeral and reproducible Bazel builds [![Test status](https://github.com/filmil/bazel_local_nix/workflows/Test/badge.svg)](https://github.com/filmil/bazel_local_nix/workflows/Test/badge.svg)

This is an experiment in fully hermetic, but also self-installing [nix][nx]
based hermetic bazel build.

[nx]: https://nixos.org

The build rules at https://github.com/tweag/rules_nixpkgs allow bazel to bring
in dependencies from [nixpkgs][nxp]. But, it requires having a `/nix/store` on
your machine, which in turn means you need to have a pre-existing system-wide
nix installation.

[nxp]: https://github.com/NixOS/nixpkgs

This repository goes one step further: `bazel` will install an **ephemeral**
nix store and pull in the appropriate dependencies from nixpkgs. This means that
you **do not** need to install nix on your system to use the packages from nixpkgs.
`bazel` will do that for you. Moreover, the resulting nix installation will be
**ephemeral** and will only take effect within your bazel workspace.

## References

See how this is used in the [integration test repo][itr].

[itr]: https://github.com/filmil/bazel_local_nix/tree/main/integration

Read [the article describing the approach][ta].

[ta]: https://hdlfactory.com/post/2024/04/20/nix-bazel-%EF%B8%8F/

## Installation

Add the following to your WORKSPACE file:

```
load("@bazel_tools//tools/build_defs/repo:git.bzl", "git_repository")

git_repository(
    name = "bazel_local_nix",
	remote = "https://github.com/filmil/bazel_local_nix",
	commit = "d2daf82dfa7dc1ff7eafe12fa91c19b8fa417f15",
)

load("@bazel_local_nix//:repositories.bzl", "bazel_local_nix_dependencies")
bazel_local_nix_dependencies()
```

Then, install the tools:

```
bazel --max_idle_secs=1 run @bazel_local_nix//:install
```

You can now set up the rest of this project.

