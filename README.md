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
load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_archive")

http_archive(
    name = "rules_cc",
    sha256 = "4dccbfd22c0def164c8f47458bd50e0c7148f3d92002cdb459c2a96a68498241",
    urls = [
        "https://github.com/bazelbuild/rules_cc/releases/download/0.0.1/rules_cc-0.0.1.tar.gz",
    ],
)
http_archive(
    name = "io_tweag_rules_nixpkgs",
    strip_prefix = "rules_nixpkgs-126e9f66b833337be2c35103ce46ab66b4e44799",
    urls = ["https://github.com/tweag/rules_nixpkgs/archive/126e9f66b833337be2c35103ce46ab66b4e44799.tar.gz"],
    sha256 = "480df4a7777a5e3ee7a755ab38d18ecb3ddb7b2e2435f24ad2037c1b084faa65",
)
load("@io_tweag_rules_nixpkgs//nixpkgs:repositories.bzl", "rules_nixpkgs_dependencies")
rules_nixpkgs_dependencies()
load("@io_tweag_rules_nixpkgs//nixpkgs:nixpkgs.bzl", "nixpkgs_local_repository")
nixpkgs_local_repository(
    name = "nixpkgs",
    nix_flake_lock_file = "//:flake.lock",
    nix_file_deps = ["//:flake.lock"],
)
# Configure the C++ toolchain
load("@io_tweag_rules_nixpkgs//nixpkgs:nixpkgs.bzl", "nixpkgs_cc_configure")
nixpkgs_cc_configure(
    name = "nixpkgs_config_cc",
    repository = "@nixpkgs",
    attribute_path = "clang_13",
)
load("@rules_cc//cc:repositories.bzl", "rules_cc_dependencies", "rules_cc_toolchains")
rules_cc_dependencies()
rules_cc_toolchains()

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

You can now set up the rest of this project. Note that if you are setting
up ephemeral nix for the entire project, you may need to turn off any early
toolchain checks.  Place such checks under an env-protected flag, place
it under `//tools/bazel_local_nix.config.sh`. This will be used to bootstrap
installation for everyone else checking out the source.

