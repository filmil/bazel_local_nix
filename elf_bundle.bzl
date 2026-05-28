# SPDX-License-Identifier: Apache-2.0
# elf_bundle.bzl
#
# A rule that mimics `clodl` by bundling a binary and all its transitive
# shared library dependencies into a single self-extracting archive.

def _self_extracting_binary_impl(ctx):
    binary = ctx.executable.binary
    output = ctx.actions.declare_file(ctx.label.name + ".sh")
    nix_wrapper = ctx.executable._nix_wrapper

    # Collect runfiles to ensure all transitive shared libraries and data are available.
    runfiles = ctx.attr.binary[DefaultInfo].default_runfiles.files
    runfiles_list = ctx.actions.declare_file(ctx.label.name + ".runfiles_list")
    ctx.actions.write(
        output = runfiles_list,
        content = "\n".join(["{path} {short_path}".format(path=f.path, short_path=f.short_path) for f in runfiles.to_list()]),
    )

    # Discovery and bundling script.
    # We use ldd and readelf to find dependencies. Since the input binary
    # may have been built with a Nix-backed toolchain, it will have RPATHs
    # pointing to the Nix store, allowing ldd to resolve them.
    script = """
set -euo pipefail

BINARY="{binary}"
OUTPUT="{output}"
WRAPPER="{nix_wrapper}"
RUNFILES_LIST="{runfiles_list}"

# Get patchelf from Nix
PATCHELF_HOST=$("$WRAPPER" build --no-link --print-out-paths nixpkgs#patchelf | tail -n 1)/bin/patchelf
PATCHELF_GUEST="/nix/store/$(echo "$PATCHELF_HOST" | sed "s|.*/nix/store/||")"

# Create staging dir in current directory so it's visible to the wrapper sandbox
WORK=$(mktemp -d -p "$(pwd)")
chmod 755 "$WORK"
mkdir -p "$WORK/lib" "$WORK/bin"
chmod 755 "$WORK/lib" "$WORK/bin"

# Copy binary
BIN_NAME=$(basename "$BINARY")
cp "$BINARY" "$WORK/bin/$BIN_NAME"
chmod u+w "$WORK/bin/$BIN_NAME"
chmod +x "$WORK/bin/$BIN_NAME"

# Find the interpreter (ld.so)
INTERP=$("$WRAPPER" exec /usr/bin/readelf -l "$BINARY" | grep 'Requesting program interpreter' | sed -e 's/.*: \\(.*\\)]/\\1/' || true)
if [ -z "$INTERP" ]; then
    # Try to find it via ldd if readelf failed
    INTERP=$("$WRAPPER" exec /usr/bin/ldd "$BINARY" | grep "ld-linux" | awk '{{print $1}}' | grep "^/" || true)
fi

LD_SO=""
if [ -n "$INTERP" ] && "$WRAPPER" exec /usr/bin/test -f "$INTERP"; then
    # Copy the interpreter from the guest path
    # We need to use the wrapper to copy it if it's in /nix/store
    "$WRAPPER" exec /usr/bin/cp -L "$INTERP" "$WORK/lib/"
    chmod u+w "$WORK/lib/$(basename "$INTERP")"
    LD_SO=$(basename "$INTERP")
else
    # Fallback: look for any ld-linux in ldd output
    LD_SO_PATH=$("$WRAPPER" exec /usr/bin/ldd "$BINARY" | grep "ld-linux" | awk '{{print $3}}' | grep "^/" || "$WRAPPER" exec /usr/bin/ldd "$BINARY" | grep "ld-linux" | awk '{{print $1}}' | grep "^/" || true)
    if [ -n "$LD_SO_PATH" ]; then
        "$WRAPPER" exec /usr/bin/cp -L "$LD_SO_PATH" "$WORK/lib/"
        chmod u+w "$WORK/lib/$(basename "$LD_SO_PATH")"
        LD_SO=$(basename "$LD_SO_PATH")
    else
        echo "Warning: Could not find dynamic linker for $BINARY" >&2
    fi
fi

# Collect libraries and data from runfiles
if [ -f "$RUNFILES_LIST" ]; then
    mkdir -p "$WORK/runfiles"
    while read -r f short_path; do
        [ -f "$f" ] || continue
        mkdir -p "$WORK/runfiles/$(dirname "$short_path")"
        cp -L "$f" "$WORK/runfiles/$short_path"
        chmod u+w "$WORK/runfiles/$short_path"
        if [[ "$f" == *.so* ]]; then
            cp -L "$f" "$WORK/lib/"
            chmod u+w "$WORK/lib/$(basename "$f")"
        fi
    done < "$RUNFILES_LIST"
fi

# Collect all other libraries via ldd
# Filter out linux-vdso.so and other virtual libraries
"$WRAPPER" exec /usr/bin/ldd "$BINARY" | while read -r line; do
  if echo "$line" | grep -q "=>"; then
    lib_path=$(echo "$line" | awk '{{print $3}}')
    if [ -n "$lib_path" ] && [ "$lib_path" != "not" ]; then
      dest="$WORK/lib/$(basename "$lib_path")"
      if [ ! -e "$dest" ]; then
        "$WRAPPER" exec /usr/bin/cp -L "$lib_path" "$dest"
        chmod u+w "$dest"
      fi
    fi
  fi
done

# Patch the binary and libraries to use relative RPATH
# This allows them to find each other without LD_LIBRARY_PATH
# $ORIGIN/../lib for the binary in bin/
"$WRAPPER" exec "$PATCHELF_GUEST" --set-rpath '$ORIGIN/../lib' "$WORK/bin/$BIN_NAME"

# $ORIGIN for libraries in lib/
for lib in "$WORK/lib/"*; do
    [ -f "$lib" ] || continue
    # Skip the dynamic linker itself, patching it can break it
    [ "$(basename "$lib")" = "$LD_SO" ] && continue
    
    # Only patch if it's an ELF file
    if "$WRAPPER" exec /usr/bin/readelf -h "$lib" >/dev/null 2>&1; then
        "$WRAPPER" exec "$PATCHELF_GUEST" --set-rpath '$ORIGIN' "$lib" || true
    fi
done

# Create run shim
cat << EOF > "$WORK/run.sh"
#!/bin/sh
HERE=\\$(cd "\\$(dirname "\\$0")" && pwd)
export RUNFILES_DIR="\\$HERE/runfiles"
if [ -n "$LD_SO" ]; then
    # We still need to call the interpreter explicitly because it must be absolute.
    # But since we patched RPATH, we don't need --library-path if we don't want to.
    # However, passing it doesn't hurt and ensures we use our bundled libs.
    exec "\\$HERE/lib/$LD_SO" --library-path "\\$HERE/lib" "\\$HERE/bin/$BIN_NAME" "\\$@"
else
    # Fallback to host ld.so if we couldn't bundle one
    LD_LIBRARY_PATH="\\$HERE/lib:\\${{LD_LIBRARY_PATH:-}}" exec "\\$HERE/bin/$BIN_NAME" "\\$@"
fi
EOF
chmod +x "$WORK/run.sh"

# Create tarball
tar czf "$WORK/payload.tar.gz" -C "$WORK" lib bin run.sh runfiles

# Create self-extracting header
cat << 'EOF_HEADER' > "$OUTPUT"
#!/bin/sh
set -e
PAYLOAD_OFFSET=$(awk '/^__PAYLOAD_BELOW__/ {{print NR + 1; exit 0; }}' "$0")
EXTRACT_DIR=$(mktemp -d)
trap 'rm -rf "$EXTRACT_DIR"' EXIT
tail -n +$PAYLOAD_OFFSET "$0" | tar xz -C "$EXTRACT_DIR"
"$EXTRACT_DIR/run.sh" "$@"
exit $?
__PAYLOAD_BELOW__
EOF_HEADER

cat "$WORK/payload.tar.gz" >> "$OUTPUT"
chmod +x "$OUTPUT"
rm -rf "$WORK"
""".format(
        binary = binary.path,
        output = output.path,
        nix_wrapper = nix_wrapper.path,
        runfiles_list = runfiles_list.path,
    )

    ctx.actions.run_shell(
        inputs = depset(
            [binary, runfiles_list] + ctx.files._nix_binaries,
            transitive = [runfiles],
        ),
        outputs = [output],
        tools = [nix_wrapper],
        command = script,
        mnemonic = "ElfBundle",
        progress_message = "Bundling %{label} into a self-extracting archive",
        # Needs network for patchelf and local for nix_wrapper
        execution_requirements = {
            "requires-network": "1",
            "no-sandbox": "1",
            "local": "1",
        },
    )


    return [DefaultInfo(files = depset([output]), executable = output)]

self_extracting_binary = rule(
    implementation = _self_extracting_binary_impl,
    doc = """Creates a self-extracting archive of a binary and its shared library dependencies.

Traverses the transitive shared library dependencies of the given binary
using 'ldd', bundles them together with a custom dynamic linker, patches
their RPATHs using 'patchelf', and prepends a self-extracting shell header.
""",
    attrs = {
        "binary": attr.label(
            doc = "The binary target to bundle.",
            mandatory = True,
            allow_single_file = True,
            executable = True,
            cfg = "target",
        ),
        "_nix_wrapper": attr.label(
            doc = "Internal Nix wrapper script.",
            default = "@nix_bootstrap//:nix_wrapper.sh",
            executable = True,
            allow_files = True,
            cfg = "exec",
        ),
        "_nix_binaries": attr.label(
            doc = "Internal Nix binaries from bootstrap.",
            default = "@nix_bootstrap//:nix_binaries",
        ),
    },
    executable = True,
)
