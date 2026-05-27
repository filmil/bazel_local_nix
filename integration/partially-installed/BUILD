# SPDX-License-Identifier: Apache-2.0
load("@rules_nix//:nix_rules.bzl", "nix_package", "nix_toolchain")

# Integration test: bundle 'hello' from nixpkgs and run the bundled binary
# via the relocatable run-shim (no host /nix required).
nix_package(
    name = "hello_pack",
    tags = [
        "manual",
        "requires-network",
    ],
)

nix_toolchain(
    name = "hello_tool",
    bundle = ":hello_pack",
    tags = ["manual"],
)

genrule(
    name = "test_hello",
    srcs = [":hello_tool"],
    outs = ["hello_out.txt"],
    cmd = "$(location :hello_tool)/bin/hello > $@",
    tags = [
        "manual",
        "no-sandbox",
        "local",
    ],
)
