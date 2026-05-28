# SPDX-License-Identifier: Apache-2.0
load("@bazel_lib//lib:write_source_files.bzl", "write_source_files")
load("@bazel_skylib//:bzl_library.bzl", "bzl_library")
load("@bazel_skylib//rules:build_test.bzl", "build_test")
load("@gazelle//:def.bzl", "DEFAULT_LANGUAGES", "gazelle", "gazelle_binary")
load("@rules_shell//shell:sh_test.bzl", "sh_test")
load("@stardoc//stardoc:stardoc.bzl", "stardoc")
load(":nix_rules.bzl", "nix_package", "nix_toolchain")

exports_files([
    "nix_wrapper.sh.tpl",
    "nix_run_shim.sh",
    "nix_cc_wrapper.sh.tpl",
    "nix_package_build.sh.tpl",
    "nix_extract.sh.tpl",
    "elf_bundle.bzl",
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
    name = "nix_rules_docs_gen",
    out = "nix_rules.md",
    input = "nix_rules.bzl",
    deps = [":nix_rules"],
)

stardoc(
    name = "nix_bootstrap_docs_gen",
    out = "nix_bootstrap.md",
    input = "nix_bootstrap.bzl",
    deps = [":nix_bootstrap"],
)

stardoc(
    name = "elf_bundle_docs_gen",
    out = "elf_bundle.md",
    input = "elf_bundle.bzl",
    deps = [":elf_bundle"],
)

stardoc(
    name = "nix_cc_docs_gen",
    out = "nix_cc.md",
    input = "nix_cc.bzl",
    deps = [":nix_cc"],
)

stardoc(
    name = "extensions_docs_gen",
    out = "extensions.md",
    input = "extensions.bzl",
    deps = [":extensions"],
)

write_source_files(
    name = "update_docs",
    files = {
        "docs/nix_rules.md": ":nix_rules_docs_gen",
        "docs/nix_bootstrap.md": ":nix_bootstrap_docs_gen",
        "docs/elf_bundle.md": ":elf_bundle_docs_gen",
        "docs/nix_cc.md": ":nix_cc_docs_gen",
        "docs/extensions.md": ":extensions_docs_gen",
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
    deps = [":nix_cc"],
)

# Offline smoke test: the rules and docs analyze without touching the network.
build_test(
    name = "offline_build_test",
    targets = [
        ":nix_bootstrap",
        ":nix_rules",
        ":nix_bootstrap_docs_gen",
        ":nix_rules_docs_gen",
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
