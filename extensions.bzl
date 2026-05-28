# SPDX-License-Identifier: Apache-2.0
# extensions.bzl
#
# Module extension that configures a Nix-backed Bazel C/C++ toolchain. Usage in
# MODULE.bazel:
#
#     nix_cc = use_extension("@rules_nix//:extensions.bzl", "nix_cc")
#     nix_cc.configure(
#         attribute = "gcc",
#         nixpkgs = "github:NixOS/nixpkgs/<rev>",
#     )
#     use_repo(nix_cc, "nix_cc_toolchain")
#     register_toolchains("@nix_cc_toolchain//:toolchain")

load("//:nix_cc.bzl", "nix_cc_repo")

# Keep in sync with nix_rules.bzl's pinned default (reproducibility, LIM-2).
_DEFAULT_NIXPKGS = "github:NixOS/nixpkgs/b134951a4c9f3c995fd7be05f3243f8ecd65d798"

def _nix_cc_impl(module_ctx):
    print("DEBUG: entering _nix_cc_impl")
    for mod in module_ctx.modules:
        for cfg in mod.tags.configure:
            nix_cc_repo(
                name = cfg.name,
                installable = "{}#{}".format(cfg.nixpkgs, cfg.attribute),
            )

_configure = tag_class(
    attrs = {
        "name": attr.string(
            default = "nix_cc_toolchain",
            doc = "Name of the generated toolchain repository.",
        ),
        "attribute": attr.string(
            default = "gcc",
            doc = "nixpkgs attribute providing the C/C++ compiler.",
        ),
        "nixpkgs": attr.string(
            default = _DEFAULT_NIXPKGS,
            doc = "Pinned nixpkgs flake reference (without the #attribute).",
        ),
    },
)

nix_cc = module_extension(
    implementation = _nix_cc_impl,
    doc = """Module extension that configures a Nix-backed C/C++ toolchain.

Allows configuring a compiler from nixpkgs (e.g. gcc, clang) which will
be automatically registered as a Bazel cc_toolchain.
""",
    tag_classes = {"configure": _configure},
)
