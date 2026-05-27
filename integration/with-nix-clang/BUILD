# SPDX-License-Identifier: Apache-2.0
load("@rules_cc//cc:defs.bzl", "cc_binary")
load("@rules_shell//shell:sh_test.bzl", "sh_test")

# Built by the Nix-backed cc_toolchain registered in MODULE.bazel. The compiler
# runs under bwrap against the toolchain's bundled /nix/store, so cc actions
# must use the local spawn strategy (see .bazelrc) and the resulting binary is
# itself run under bwrap.
cc_binary(
    name = "hello",
    srcs = ["hello.cc"],
    tags = ["manual"],
)

# A dummy test to ensure `bazel test //...` succeeds.
sh_test(
    name = "dummy_test",
    srcs = ["dummy_test.sh"],
)
