# SPDX-License-Identifier: Apache-2.0
load("@rules_cc//cc:defs.bzl", "cc_binary")
load("@rules_nix//:elf_bundle.bzl", "self_extracting_binary")
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

# A self-extracting bundle of the hello binary.
self_extracting_binary(
    name = "hello_bundle",
    binary = ":hello",
    tags = ["manual"],
)

# Test that the bundle runs and produces the expected output.
sh_test(
    name = "bundle_test",
    srcs = ["test_bundle.sh"],
    args = ["$(location :hello_bundle)"],
    data = [":hello_bundle"],
    tags = ["manual"],
)

# A dummy test to ensure `bazel test //...` succeeds.
sh_test(
    name = "dummy_test",
    srcs = ["dummy_test.sh"],
)
