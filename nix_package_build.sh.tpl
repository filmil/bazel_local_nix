#!/bin/bash
# SPDX-License-Identifier: Apache-2.0
#
# Build script for the nix_package rule, materialized per target by
# expand_template (placeholders %{...}%). Realizes the installable from the
# binary cache, gathers its runtime closure, and tars it (plus relocatable bin/
# shims and a bundled static bwrap) into the output. The wrapper rewrites the
# guest /nix/store paths it prints to host locations under the persistent
# CACHE_BASE, so STORE_OUT/CLOSURE are readable here.
set -euo pipefail
WRAPPER="%{WRAPPER}%"
INSTALLABLE="%{INSTALLABLE}%"
OUT="%{OUT}%"
SHIM="%{SHIM}%"
BWRAP="%{BWRAP}%"

STORE_OUT=$("$WRAPPER" build --no-link --print-out-paths "$INSTALLABLE" | tail -n 1)
if [ -z "$STORE_OUT" ] || [ ! -e "$STORE_OUT" ]; then
    echo "nix_package: failed to realize $INSTALLABLE (got: '$STORE_OUT')" >&2
    exit 1
fi
GUEST_OUT="/nix/store/$(basename "$STORE_OUT")"
CLOSURE=$("$WRAPPER" path-info -r "$INSTALLABLE")

WORK=$(mktemp -d)
mkdir -p "$WORK/bin" "$WORK/nix/store"
printf '%s\n' "$GUEST_OUT" > "$WORK/.nix_out"

# Ship the static bwrap at the bundle root so the run-shim can exec it
# ("$HERE/bwrap") on a host with no bwrap of its own.
cp "$BWRAP" "$WORK/bwrap"
chmod +x "$WORK/bwrap"

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
