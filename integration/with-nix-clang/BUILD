# SPDX-License-Identifier: Apache-2.0
load("@rules_nix//:nix_rules.bzl", "nix_package", "nix_toolchain")

# Placeholder for the upcoming Nix-backed CC toolchain (see README.md). For now
# this obtains a C/C++ compiler from nixpkgs as a relocatable bundle and runs
# it via the bundle's run-shim. A future revision will turn this into a real
# Bazel cc_toolchain configured in MODULE.bazel (rules_nix spec FUT-2), at
# which point hello.cc will be built with a normal cc_binary.
#
# All targets are tagged "manual": they reach the network and run nix under
# bwrap, so they are excluded from `bazel build/test //...` and from CI.
nix_package(
    name = "cc_pack",
    installable = "github:NixOS/nixpkgs/b134951a4c9f3c995fd7be05f3243f8ecd65d798#gcc",
    tags = [
        "manual",
        "requires-network",
    ],
)

nix_toolchain(
    name = "cc_tool",
    bundle = ":cc_pack",
    tags = ["manual"],
)

genrule(
    name = "compiler_version",
    srcs = [":cc_tool"],
    outs = ["gcc_version.txt"],
    cmd = "$(location :cc_tool)/bin/g++ --version > $@",
    tags = [
        "manual",
        "no-sandbox",
        "local",
    ],
)
