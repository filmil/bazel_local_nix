# SPDX-License-Identifier: Apache-2.0
load("@rules_cc//cc:defs.bzl", "cc_binary")

# Built by the Nix-backed cc_toolchain registered in MODULE.bazel. The compiler
# runs under bwrap against the toolchain's bundled /nix/store, so cc actions
# must use the local spawn strategy (see .bazelrc) and the resulting binary is
# itself run under bwrap.
cc_binary(
    name = "hello",
    srcs = ["hello.cc"],
    tags = ["manual"],
)
