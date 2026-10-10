# SPDX-License-Identifier: Apache-2.0
#
# Documentation generation lives in its own package so that the rules_nix root
# package stays loadable by consumers: @stardoc is a dev_dependency of
# rules_nix and is therefore not visible when rules_nix is consumed as a
# module, and a load() of it from the root BUILD breaks every downstream
# target that depends on a root-package file (e.g. nix_package's
# :nix_package_build.sh.tpl). See issue #45.
load("@stardoc//stardoc:stardoc.bzl", "stardoc")

stardoc(
    name = "nix_rules_docs_gen",
    out = "nix_rules.out.md",
    input = "//:nix_rules.bzl",
    deps = ["//:nix_rules"],
)

stardoc(
    name = "nix_bootstrap_docs_gen",
    out = "nix_bootstrap.out.md",
    input = "//:nix_bootstrap.bzl",
    deps = ["//:nix_bootstrap"],
)

stardoc(
    name = "elf_bundle_docs_gen",
    out = "elf_bundle.out.md",
    input = "//:elf_bundle.bzl",
    deps = ["//:elf_bundle"],
)

stardoc(
    name = "nix_cc_docs_gen",
    out = "nix_cc.out.md",
    input = "//:nix_cc.bzl",
    deps = ["//:nix_cc"],
)

stardoc(
    name = "extensions_docs_gen",
    out = "extensions.out.md",
    input = "//:extensions.bzl",
    deps = ["//:extensions"],
)

stardoc(
    name = "nix_gnat_docs_gen",
    out = "nix_gnat.out.md",
    input = "//:nix_gnat.bzl",
    deps = ["//:nix_gnat"],
)
