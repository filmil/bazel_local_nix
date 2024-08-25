# Integration testing repository

This repo is used to demo and test the installation and use of `bazel_local_nix`.

The approach is outlined in [the test definition](../.github/workflows/test.yml).

## Installation approach

Add the following to your WORKSPACE file:

```
# This one is unique to the integration test.
# TBD: actual.
local_repository(
    name = "bazel_local_nix",
    path = "../",
)

# Installation.
load("@bazel_local_nix//:repositories.bzl", "bazel_local_nix_dependencies")
bazel_local_nix_dependencies()
```

Then, install the tools:

```
bazel --max_idle_secs=1 run @bazel_local_nix//:install
```

You can now set up the nix side of this project.

Once installed, you can do:

```
bazel run --crosstool_top=@nixpkgs_config_cc//:toolchain //:hello
```

This will install, build and run the nix-scoped `hello` binary.
