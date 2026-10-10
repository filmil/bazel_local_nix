#!/usr/bin/env bash
# SPDX-License-Identifier: Apache-2.0
#
# Extract script for the nix_toolchain rule, materialized per target by
# expand_template (placeholders %{...}%): unpacks a nix_package bundle into a
# directory tree that downstream rules can read.
set -euo pipefail
OUT_DIR="%{OUT_DIR}%"
BUNDLE="%{BUNDLE}%"

mkdir -p "$OUT_DIR"
tar -xzf "$BUNDLE" -C "$OUT_DIR"

# A Nix closure contains absolute inter-store-path symlinks (e.g. a util-linux
# sbin entry pointing at /nix/store/<other-output>/bin/...). In the extracted
# tree those targets live under $OUT_DIR/nix/store, so from the host's point of
# view the links dangle -- and Bazel rejects tree artifacts containing
# dangling symlinks (issue #47). Rewrite each such link to a relative path:
# the run-shim binds the tree's nix/store at /nix/store, where the relative and
# absolute forms resolve identically.
store="$OUT_DIR/nix/store"
if [ -d "$store" ]; then
    while IFS= read -r -d '' link; do
        target=$(readlink "$link")
        case "$target" in
            /nix/store/*)
                in_tree="$store/${target#/nix/store/}"
                if [ -e "$in_tree" ]; then
                    ln -sfn "$(realpath -m --relative-to="$(dirname "$link")" "$in_tree")" "$link"
                fi
                ;;
        esac
    done < <(find "$store" -type l -print0)
fi
