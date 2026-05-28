# SPDX-License-Identifier: Apache-2.0
# nix_rules.bzl
#
# Build rules that turn a Nix installable into a Bazel-tracked archive
# (nix_package) and unpack such an archive into a usable directory tree
# (nix_toolchain). These are the Nix analogs of rules_guix's guix_package /
# guix_toolchain.

# A pinned nixpkgs reference keeps outputs reproducible (LIM-2). Bumping this
# rev is the supported way to move the default package set.
_DEFAULT_NIXPKGS = "github:NixOS/nixpkgs/b134951a4c9f3c995fd7be05f3243f8ecd65d798"
_DEFAULT_INSTALLABLE = _DEFAULT_NIXPKGS + "#hello"

def _nix_package_impl(ctx):
    output_tarball = ctx.actions.declare_file(ctx.label.name + ".tar.gz")
    nix_wrapper = ctx.executable._nix_wrapper
    shim = ctx.file._run_shim
    bwrap = ctx.file._bwrap

    # Realize the installable and tar its closure (plus relocatable bin/ shims
    # and a bundled static bwrap) into the output. The build steps live in
    # nix_package_build.sh.tpl -- kept as a real shell file so it stays lintable
    # and free of escaping -- and are materialized per target by expand_template.
    build_script = ctx.actions.declare_file(ctx.label.name + "_build.sh")
    ctx.actions.expand_template(
        template = ctx.file._build_tpl,
        output = build_script,
        is_executable = True,
        substitutions = {
            "%{WRAPPER}%": nix_wrapper.path,
            "%{INSTALLABLE}%": ctx.attr.installable,
            "%{OUT}%": output_tarball.path,
            "%{SHIM}%": shim.path,
            "%{BWRAP}%": bwrap.path,
        },
    )

    ctx.actions.run_shell(
        outputs = [output_tarball],
        # bwrap is both copied into the bundle and required at $REPO_ROOT/bwrap
        # by the wrapper that runs nix; listing it as an input stages it next to
        # the wrapper in the bootstrap repo.
        inputs = ctx.files._nix_binaries + [shim, bwrap, build_script],
        tools = [nix_wrapper],
        command = build_script.path,
        mnemonic = "NixPackage",
        progress_message = "Building Nix package %s" % ctx.attr.installable,
        # nix build reads/writes a persistent store that survives across builds
        # (see nix_wrapper.sh.tpl). That is inherently non-hermetic, so the
        # action must run locally and un-sandboxed: it needs network access for
        # substitutes and a stable, real execroot path from which to locate the
        # persistent cache directory. (FR-PKG-3)
        execution_requirements = {
            "requires-network": "1",
            "no-sandbox": "1",
            "local": "1",
        },
    )

    return [DefaultInfo(files = depset([output_tarball]))]

nix_package = rule(
    implementation = _nix_package_impl,
    doc = """Builds a Nix installable into a self-contained, relocatable <name>.tar.gz bundle.

The produced bundle contains the full runtime closure of the installable,
with absolute /nix/store paths preserved. It also includes relocatable
bin/ shims and a bundled static bwrap that allow running the bundled
binaries on hosts without a local /nix/store or a host-provided bwrap.

Example:
    ```starlark
    load("@rules_nix//:nix_rules.bzl", "nix_package")

    nix_package(
        name = "hello_pkg",
        installable = "nixpkgs#hello",
    )
    ```
""",
    attrs = {
        "installable": attr.string(
            doc = "Nix installable to build (a pinned flake reference, e.g. 'nixpkgs#hello').",
            default = _DEFAULT_INSTALLABLE,
        ),
        "_nix_wrapper": attr.label(
            doc = "Internal Nix wrapper script.",
            default = Label("@nix_bootstrap//:nix_wrapper.sh"),
            executable = True,
            allow_files = True,
            cfg = "exec",
        ),
        "_nix_binaries": attr.label(
            doc = "Internal Nix binaries from bootstrap.",
            default = Label("@nix_bootstrap//:nix_binaries"),
        ),
        "_run_shim": attr.label(
            doc = "Internal run-shim script.",
            default = Label("@nix_bootstrap//:nix_run_shim.sh"),
            allow_single_file = True,
        ),
        "_bwrap": attr.label(
            doc = "Internal statically-linked bwrap binary from bootstrap.",
            default = Label("@nix_bootstrap//:bwrap"),
            allow_single_file = True,
            cfg = "exec",
        ),
        "_build_tpl": attr.label(
            doc = "Template for the per-target package build script.",
            default = Label("//:nix_package_build.sh.tpl"),
            allow_single_file = True,
        ),
    },
)

def _nix_toolchain_impl(ctx):
    bundle = ctx.file.bundle
    out_dir = ctx.actions.declare_directory(ctx.label.name + "_extracted")

    # The extract steps live in nix_extract.sh.tpl, materialized per target by
    # expand_template (consistent with nix_package's build script).
    extract_script = ctx.actions.declare_file(ctx.label.name + "_extract.sh")
    ctx.actions.expand_template(
        template = ctx.file._extract_tpl,
        output = extract_script,
        is_executable = True,
        substitutions = {
            "%{OUT_DIR}%": out_dir.path,
            "%{BUNDLE}%": bundle.path,
        },
    )

    ctx.actions.run_shell(
        inputs = [bundle, extract_script],
        outputs = [out_dir],
        command = extract_script.path,
        mnemonic = "ExtractNixBundle",
    )

    return [DefaultInfo(files = depset([out_dir]))]

nix_toolchain = rule(
    implementation = _nix_toolchain_impl,
    doc = """Extracts a nix_package bundle into a usable directory tree.

Downstream rules can then invoke binaries from the extracted tree
(e.g. '<extracted_dir>/bin/hello').

Example:
    ```starlark
    load("@rules_nix//:nix_rules.bzl", "nix_package", "nix_toolchain")

    nix_package(
        name = "hello_pkg",
        installable = "nixpkgs#hello",
    )

    nix_toolchain(
        name = "hello_toolchain",
        bundle = ":hello_pkg",
    )
    ```
""",
    attrs = {
        "bundle": attr.label(
            doc = "A nix_package output (.tar.gz) to extract.",
            mandatory = True,
            allow_single_file = [".tar.gz"],
        ),
        "_extract_tpl": attr.label(
            doc = "Template for the per-target bundle extract script.",
            default = Label("//:nix_extract.sh.tpl"),
            allow_single_file = True,
        ),
    },
)
