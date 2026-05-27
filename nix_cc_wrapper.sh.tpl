#!/bin/bash
# SPDX-License-Identifier: Apache-2.0
#
# Generic Bazel cc-toolchain tool wrapper, materialized once per tool (gcc, ld,
# ar, ...) in a nix_cc toolchain repository. The tool name is taken from $0.
#
# A Nix compiler and the objects it produces reference absolute /nix/store
# paths (interpreter, RPATH, the cc-wrapper's baked include/lib dirs). There is
# no host /nix, so we run the real tool inside a bwrap user namespace that:
#   - keeps the real filesystem visible (so Bazel's execroot / output_base /
#     source files resolve), via a tmpfs root with the host dirs bound back,
#   - overlays this toolchain's own store at /nix/store.
# Because it relies on the real on-disk layout and an unprivileged user
# namespace, cc actions using this toolchain must run with the local spawn
# strategy (no nested Bazel sandbox); see the toolchain README.
set -e

HERE="$(cd "$(dirname "$(readlink -f "$0")")/.." && pwd)"
STORE="$HERE/nix/store"
TOOL="$(basename "$0")"

# Bazel runs cc actions with an empty environment (`env -`) and cwd at the
# execroot, with source inputs symlinked to the real source tree and the
# repository cache. We cannot know where those live ($HOME is unset here), so
# rather than guess we reconstruct the real root: bind every top-level entry of
# / into the namespace, then overlay this toolchain's store at /nix/store. This
# is intentionally non-hermetic (it sees the whole host fs) but makes every
# path Bazel passes resolve.
#
# Use the *physical* cwd, not $PWD: Bazel sets PWD=/proc/self/cwd, which would
# make --chdir and any cwd-derived path bogus.
EXECROOT="$(pwd -P)"

binds=(--tmpfs / --dev /dev --proc /proc --bind /tmp /tmp)
for entry in /*; do
    case "$entry" in
        /nix | /dev | /proc | /tmp | /sys) continue ;;
    esac
    [ -e "$entry" ] && binds+=(--bind "$entry" "$entry")
done
binds+=(
    --dir /nix
    --bind "$STORE" /nix/store
    --chdir "$EXECROOT"
    --setenv PATH "%{GUEST_PATH}%"
)

exec bwrap "${binds[@]}" /usr/bin/env "$TOOL" "$@"
