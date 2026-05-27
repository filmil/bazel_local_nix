#!/bin/bash
# SPDX-License-Identifier: Apache-2.0
#
# Generic relocatable run-shim copied into a nix_package bundle as bin/<tool>.
# A Nix closure's binaries hold absolute /nix/store/... interpreter and RPATH
# references, so they only run when that store content is present at
# /nix/store. This shim re-execs the real store binary under bwrap with the
# bundle's own store bound at /nix/store, making the bundle runnable on any
# host with bubblewrap and unprivileged user namespaces -- no /nix on the host
# required. The same file backs every executable in the bundle; the tool name
# is taken from $0.
set -e

HERE="$(cd "$(dirname "$(readlink -f "$0")")/.." && pwd)"
PKG="$(cat "$HERE/.nix_out")"
TOOL="$(basename "$0")"

exec bwrap \
    --bind "$HERE/nix/store" /nix/store \
    --proc /proc \
    --dev /dev \
    --tmpfs /tmp \
    --ro-bind-try /etc/resolv.conf /etc/resolv.conf \
    --ro-bind-try /etc/ssl /etc/ssl \
    --ro-bind-try /etc/passwd /etc/passwd \
    --ro-bind-try /etc/group /etc/group \
    --setenv PATH "$PKG/bin" \
    "$PKG/bin/$TOOL" "$@"
