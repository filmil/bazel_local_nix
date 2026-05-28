# SPDX-License-Identifier: Apache-2.0
load("@rules_nix//:elf_bundle.bzl", "self_extracting_binary")
load("@rules_shell//shell:sh_test.bzl", "sh_test")

load("@rules_nix//:nix_gnat.bzl", "ada_binary", "ada_library")

ada_library(
    name = "greet",
    srcs = ["greet.adb", "greet.ads"],
)

ada_binary(
    name = "hello_bin",
    srcs = ["hello.adb"],
    deps = [":greet"],
)

# A self-extracting bundle of the hello binary.
self_extracting_binary(
    name = "hello_bundle",
    binary = ":hello_bin",
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
