# SPDX-License-Identifier: Apache-2.0
load("@bazel_lib//lib:write_source_files.bzl", "write_source_files")
load("@bazel_skylib//:bzl_library.bzl", "bzl_library")
load("@bazel_skylib//rules:build_test.bzl", "build_test")
load("@gazelle//:def.bzl", "DEFAULT_LANGUAGES", "gazelle", "gazelle_binary")
load("@rules_shell//shell:sh_test.bzl", "sh_test")
load(":nix_rules.bzl", "nix_package", "nix_toolchain")

exports_files([
    "elf_bundle.bzl",
    "extensions.bzl",
    "nix_bootstrap.bzl",
    "nix_cc.bzl",
    "nix_gnat.bzl",
    "nix_rules.bzl",
    "nix_wrapper.sh.tpl",
    "nix_run_shim.sh",
    "nix_cc_wrapper.sh.tpl",
    "nix_package_build.sh.tpl",
    "nix_extract.sh.tpl",
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

write_source_files(
    name = "update_docs",
    files = {
        "nix_rules.md": "//docs:nix_rules_docs_gen",
        "nix_bootstrap.md": "//docs:nix_bootstrap_docs_gen",
        "elf_bundle.md": "//docs:elf_bundle_docs_gen",
        "nix_cc.md": "//docs:nix_cc_docs_gen",
        "extensions.md": "//docs:extensions_docs_gen",
        "nix_gnat.md": "//docs:nix_gnat_docs_gen",
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
        "local",
        "manual",
        "no-sandbox",
    ],
)

genrule(
    name = "test_nix_version",
    srcs = [
        "@nix_bootstrap//:nix_binaries",
        "@nix_bootstrap//:nix_wrapper.sh",
        # The wrapper execs the bundled static bwrap from its own dir.
        "@nix_bootstrap//:bwrap",
    ],
    outs = ["nix_version.txt"],
    cmd = "$(location @nix_bootstrap//:nix_wrapper.sh) --version > $@ 2>&1 || true",
    tags = [
        "local",
        "manual",
        "no-sandbox",
        "requires-network",
    ],
)

bzl_library(
    name = "bazel_tools_cc_action_names",
    srcs = ["@bazel_tools//tools/build_defs/cc:action_names.bzl"],
)

bzl_library(
    name = "bazel_tools_cpp_cc_toolchain_config_lib",
    srcs = ["@bazel_tools//tools/cpp:cc_toolchain_config_lib.bzl"],
)

bzl_library(
    name = "rules_cc_cc_toolchain_config_lib_bzl",
    srcs = ["@rules_cc//cc:cc_toolchain_config_lib.bzl"],
)

bzl_library(
    name = "nix_cc",
    srcs = ["nix_cc.bzl"],
    visibility = ["//visibility:public"],
    deps = [
        ":bazel_tools_cc_action_names",
        ":bazel_tools_cpp_cc_toolchain_config_lib",
        ":rules_cc_cc_toolchain_config_lib_bzl",
    ],
)

bzl_library(
    name = "extensions",
    srcs = ["extensions.bzl"],
    visibility = ["//visibility:public"],
    deps = [
        ":nix_cc",
        ":nix_gnat",
    ],
)

# Offline smoke test: the rules and docs analyze without touching the network.
build_test(
    name = "offline_build_test",
    targets = [
        ":nix_bootstrap",
        ":nix_rules",
        "//docs:nix_bootstrap_docs_gen",
        "//docs:nix_rules_docs_gen",
        "//docs:nix_gnat_docs_gen",
    ],
)

# A dummy test to ensure `bazel test //...` succeeds.
sh_test(
    name = "dummy_test",
    srcs = ["dummy_test.sh"],
)

bzl_library(
    name = "elf_bundle",
    srcs = ["elf_bundle.bzl"],
    visibility = ["//visibility:public"],
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

bzl_library(
    name = "nix_gnat",
    srcs = ["nix_gnat.bzl"],
    visibility = ["//visibility:public"],
)
