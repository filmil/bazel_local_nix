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

    # Realize the installable from the binary cache, gather its runtime
    # closure, and tar it (plus relocatable bin/ shims) into the output. The
    # wrapper rewrites the guest /nix/store paths it prints to host locations
    # under the persistent CACHE_BASE, so STORE_OUT/CLOSURE are readable here.
    script = """
set -euo pipefail
WRAPPER="{wrapper}"
INSTALLABLE="{installable}"
OUT="{out}"
SHIM="{shim}"

STORE_OUT=$("$WRAPPER" build --no-link --print-out-paths "$INSTALLABLE" | tail -n 1)
if [ -z "$STORE_OUT" ] || [ ! -e "$STORE_OUT" ]; then
    echo "nix_package: failed to realize $INSTALLABLE (got: '$STORE_OUT')" >&2
    exit 1
fi
GUEST_OUT="/nix/store/$(basename "$STORE_OUT")"
CLOSURE=$("$WRAPPER" path-info -r "$INSTALLABLE")

WORK=$(mktemp -d)
mkdir -p "$WORK/bin" "$WORK/nix/store"
printf '%s\\n' "$GUEST_OUT" > "$WORK/.nix_out"

if [ -d "$STORE_OUT/bin" ]; then
    for exe in "$STORE_OUT/bin/"*; do
        [ -e "$exe" ] || continue
        cp "$SHIM" "$WORK/bin/$(basename "$exe")"
        chmod +x "$WORK/bin/$(basename "$exe")"
    done
fi

for p in $CLOSURE; do
    [ -e "$p" ] || continue
    cp -a "$p" "$WORK/nix/store/"
done
chmod -R u+w "$WORK/nix/store" 2>/dev/null || true

tar czf "$OUT" -C "$WORK" .
rm -rf "$WORK"
""".format(
        wrapper = nix_wrapper.path,
        installable = ctx.attr.installable,
        out = output_tarball.path,
        shim = shim.path,
    )

    ctx.actions.run_shell(
        outputs = [output_tarball],
        inputs = ctx.files._nix_binaries + [shim],
        tools = [nix_wrapper],
        command = script,
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
    doc = "Builds a Nix installable into a self-contained, relocatable " +
          "<name>.tar.gz bundle.",
    attrs = {
        "installable": attr.string(
            doc = "Nix installable to build (a pinned flake reference).",
            default = _DEFAULT_INSTALLABLE,
        ),
        "_nix_wrapper": attr.label(
            default = "@nix_bootstrap//:nix_wrapper.sh",
            executable = True,
            allow_files = True,
            cfg = "exec",
        ),
        "_nix_binaries": attr.label(default = "@nix_bootstrap//:nix_binaries"),
        "_run_shim": attr.label(
            default = "@nix_bootstrap//:nix_run_shim.sh",
            allow_single_file = True,
        ),
    },
)

def _nix_toolchain_impl(ctx):
    bundle = ctx.file.bundle
    out_dir = ctx.actions.declare_directory(ctx.label.name + "_extracted")

    script = """
    mkdir -p {out_dir}
    tar -xzf {bundle} -C {out_dir}
    """.format(bundle = bundle.path, out_dir = out_dir.path)

    ctx.actions.run_shell(
        inputs = [bundle],
        outputs = [out_dir],
        command = script,
        mnemonic = "ExtractNixBundle",
    )

    return [DefaultInfo(files = depset([out_dir]))]

nix_toolchain = rule(
    implementation = _nix_toolchain_impl,
    doc = "Extracts a nix_package bundle into a usable directory tree.",
    attrs = {
        "bundle": attr.label(
            doc = "A nix_package output (.tar.gz) to extract.",
            mandatory = True,
            allow_single_file = [".tar.gz"],
        ),
    },
)
