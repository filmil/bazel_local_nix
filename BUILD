# SPDX-License-Identifier: Apache-2.0
load("@aspect_bazel_lib//lib:write_source_files.bzl", "write_source_files")
load("@bazel_skylib//:bzl_library.bzl", "bzl_library")
load("@bazel_skylib//rules:build_test.bzl", "build_test")
load("@gazelle//:def.bzl", "DEFAULT_LANGUAGES", "gazelle", "gazelle_binary")
load("@stardoc//stardoc:stardoc.bzl", "stardoc")
load(":nix_rules.bzl", "nix_package", "nix_toolchain")

exports_files([
    "nix_wrapper.sh.tpl",
    "nix_run_shim.sh",
])

# Gazelle for Starlark
gazelle(
    name = "gazelle",
    gazelle = ":gazelle_bin",
)

gazelle_binary(
    name = "gazelle_bin",
    languages = DEFAULT_LANGUAGES + [
        "@bazel_skylib_gazelle_plugin//bzl",
    ],
)

stardoc(
    name = "docs_gen",
    out = "nix_rules.md",
    input = "nix_rules.bzl",
    deps = [":nix_rules"],
)

write_source_files(
    name = "update_docs",
    files = {
        "docs/nix_rules.md": ":docs_gen",
    },
)

# Nix Rules Example.
#
# These targets reach the network (substitutes) and run nix under bwrap, so
# they are tagged "manual" to keep them out of `bazel build/test //...` (and
# thus out of CI, which cannot rely on unprivileged user namespaces). Build
# them explicitly, e.g. `bazel build //:run_hello`.
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
    name = "run_hello",
    srcs = [":hello_tool"],
    outs = ["hello_output.txt"],
    cmd = "$(location :hello_tool)/bin/hello > $@",
    # The run-shim re-execs the bundled binary under bwrap, which needs an
    # unsandboxed local action to create a user namespace.
    tags = [
        "manual",
        "no-sandbox",
        "local",
    ],
)

genrule(
    name = "test_nix_version",
    srcs = [
        "@nix_bootstrap//:nix_binaries",
        "@nix_bootstrap//:nix_wrapper.sh",
    ],
    outs = ["nix_version.txt"],
    cmd = "$(location @nix_bootstrap//:nix_wrapper.sh) --version > $@ 2>&1 || true",
    tags = [
        "manual",
        "requires-network",
        "no-sandbox",
        "local",
    ],
)

bzl_library(
    name = "nix_bootstrap",
    srcs = ["nix_bootstrap.bzl"],
    visibility = ["//visibility:public"],
)

bzl_library(
    name = "nix_rules",
    srcs = ["nix_rules.bzl"],
    visibility = ["//visibility:public"],
)

# Offline smoke test: the rules and docs analyze without touching the network.
build_test(
    name = "offline_build_test",
    targets = [
        ":nix_bootstrap",
        ":nix_rules",
        ":docs_gen",
    ],
)
