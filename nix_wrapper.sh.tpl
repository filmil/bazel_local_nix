#!/bin/bash
# SPDX-License-Identifier: Apache-2.0
#
# Runtime wrapper that runs an arbitrary `nix` subcommand ("$@") inside a
# bwrap user namespace, against a persistent single-user Nix store. This is
# the Nix analog of rules_guix's guix_wrapper.sh.tpl. Unlike Guix, single-user
# Nix talks to no daemon and needs no socket: it operates on the store
# directly, so this wrapper is simpler (no daemon spawn, no socket wait, no
# Guile *.go timestamp handling).
set -e

REPO_ROOT=$(cd "$(dirname "$0")" && pwd)
# Use the pinned static bwrap materialized alongside this wrapper by
# nix_bootstrap, not a host-provided one (hermeticity). It is staged next to
# this script both in the bootstrap repo and in any action that lists it as an
# input.
BWRAP="$REPO_ROOT/bwrap"
if [ ! -x "$BWRAP" ]; then
    echo "nix_wrapper: bundled bwrap not found at $BWRAP" >&2
    exit 1
fi

# The release unpacks to nix-<version>-x86_64-linux/. Discover it (and the nix
# binaries within) version-agnostically so bumping the pinned release needs no
# edit here (FR-WRAP-13).
NIX_TOPDIR=$(ls -d "$REPO_ROOT"/nix-*-x86_64-linux 2>/dev/null | head -n 1)
SEED_STORE="$NIX_TOPDIR/store"
REGINFO="$NIX_TOPDIR/.reginfo"
# Path of the nix bin dir relative to the seed store, e.g.
# <hash>-nix-2.24.10/bin -- the same relative path is valid inside the sandbox
# at /nix/store/<hash>-nix-2.24.10/bin.
REL_NIX_BIN=$(ls -d "$SEED_STORE"/*-nix-[0-9]*/bin | head -n 1 | sed "s|$SEED_STORE/||")
GUEST_NIX_BIN="/nix/store/$REL_NIX_BIN"

# --- Persistent cache location -------------------------------------------
# The writable Nix store and database are kept in a directory that survives
# across Bazel builds, so substitutes are downloaded only once. By default
# this lives next to Bazel's other caches under the active output_user_root
# (i.e. .../<output_user_root>/rules_nix_store). Because the NixPackage action
# runs un-sandboxed and locally, $(pwd) is the real execroot
# (<output_base>/execroot/<workspace>), so two dirnames give the output_base
# and a third gives the output_user_root. Override with RULES_NIX_CACHE.
CACHE_BASE="${RULES_NIX_CACHE:-}"
if [ -z "$CACHE_BASE" ]; then
    output_base=$(dirname "$(dirname "$(pwd)")")
    output_user_root=$(dirname "$output_base")
    CACHE_BASE="$output_user_root/rules_nix_store"
fi
FAT_STORE="$CACHE_BASE/nix/store"
mkdir -p "$FAT_STORE"
mkdir -p "$CACHE_BASE/nix/var/nix"
mkdir -p "$CACHE_BASE/etc/nix"

# nix.conf: enable the experimental interface, use the public binary cache and
# trust its key, and run in pure single-user mode (no build-users-group, no
# nested sandbox -- we are already inside a bwrap user namespace). (FR-WRAP-5,
# FR-WRAP-8)
cat > "$CACHE_BASE/etc/nix/nix.conf" <<'EOF'
experimental-features = nix-command flakes
substituters = https://cache.nixos.org
trusted-public-keys = cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY=
build-users-group =
sandbox = false
EOF

# Per-run, ephemeral scratch for $HOME and $TMPDIR inside the sandbox.
RUN_TMP=$(mktemp -d)
mkdir -p "$RUN_TMP/home" "$RUN_TMP/tmp"

# Serialize invocations sharing the cache: single-user Nix has no daemon to
# arbitrate concurrent access to the store/database, so concurrent NixPackage
# actions must take turns. (FR-WRAP-9)
exec 9>"$CACHE_BASE/lock"
flock 9

# Guest paths: every nix invocation runs inside bwrap where the writable store
# is bound at /nix/store and state at /nix/var/nix. These MUST be guest paths
# (not host paths under $CACHE_BASE) or nix fails to find them. (FR-WRAP-6)
export HOME="/home"
export XDG_CACHE_HOME="/home/.cache"
export TMPDIR="/tmp"
export NIX_CONF_DIR="/etc/nix"
export NIX_STORE_DIR="/nix/store"
export NIX_STATE_DIR="/nix/var/nix"
export USER="${USER:-nixbld}"
# Make the host CA bundle discoverable to nix for TLS to the binary cache.
for ca in /etc/ssl/certs/ca-certificates.crt /etc/ssl/certs/ca-bundle.crt \
          /etc/pki/tls/certs/ca-bundle.crt; do
    if [ -e "$ca" ]; then
        export NIX_SSL_CERT_FILE="$ca"
        break
    fi
done

BWRAP_BASE=(
    "$BWRAP"
    --tmpfs /
    --ro-bind /usr /usr
    --ro-bind-try /bin /bin
    --ro-bind-try /lib /lib
    --ro-bind-try /lib64 /lib64
    --tmpfs /etc
    --ro-bind-try /etc/resolv.conf /etc/resolv.conf
    --ro-bind-try /etc/hosts /etc/hosts
    --ro-bind-try /etc/nsswitch.conf /etc/nsswitch.conf
    --ro-bind-try /etc/services /etc/services
    --ro-bind-try /etc/ssl /etc/ssl
    --ro-bind-try /etc/pki /etc/pki
    --ro-bind-try /etc/passwd /etc/passwd
    --ro-bind-try /etc/group /etc/group
    --dev /dev
    --proc /proc
    --dir /nix
    --bind "$FAT_STORE" /nix/store
    --bind "$CACHE_BASE/nix/var" /nix/var
    --ro-bind "$CACHE_BASE/etc/nix" /etc/nix
    --bind "$RUN_TMP/home" /home
    --bind "$RUN_TMP/tmp" /tmp
    --setenv HOME /home
    --setenv TMPDIR /tmp
    --share-net
    --die-with-parent
)

# --- One-time store initialization (FR-WRAP-3) ---------------------------
# Seed the writable store from the shipped release and register the seed paths
# in the Nix database via `nix-store --load-db < .reginfo` (the Nix analog of
# the Guix daemon DB). Guarded by a marker so it runs only once; subsequent
# builds reuse the populated store. We copy with `cp -a` (archive), preserving
# symlinks verbatim: Nix store entries reference each other by absolute
# /nix/store paths, which are dangling on the host but resolve correctly once
# the store is bound at /nix/store inside bwrap. (Dereferencing with -L would
# fail on those dangling links.)
if [ ! -e "$CACHE_BASE/.store_ready" ]; then
    echo "Initializing persistent nix store at $CACHE_BASE (one-time)..." >&2
    cp -a "$SEED_STORE"/. "$FAT_STORE"/
    chmod -R u+w "$FAT_STORE" 2>/dev/null || true
    if ! "${BWRAP_BASE[@]}" "$GUEST_NIX_BIN/nix-store" --load-db \
            < "$REGINFO" >&2; then
        echo "Error: failed to register seed store paths in the Nix DB." >&2
        rm -rf "$RUN_TMP" || true
        exit 1
    fi
    touch "$CACHE_BASE/.store_ready"
fi

cleanup() {
    rm -rf "$RUN_TMP" || true
}
trap cleanup EXIT INT TERM

# Run the requested nix subcommand. Substitution stays enabled (no
# --option substitute false) so builds download from cache.nixos.org rather
# than building from source. (FR-WRAP-8, FR-WRAP-10)
set +e
nix_output=$("${BWRAP_BASE[@]}" "$GUEST_NIX_BIN/nix" "$@")
nix_rc=$?
set -e

# nix runs against the persistent store bound at /nix/store (host:
# $CACHE_BASE/nix/store). Commands like `nix build --print-out-paths` and
# `nix path-info -r` print *guest* /nix/store paths on stdout; rewrite each to
# its host location under $CACHE_BASE so the caller can read the artifact after
# bwrap exits. Non-path output (e.g. `nix --version`) passes through untouched.
# (FR-WRAP-11)
if [ -n "$nix_output" ]; then
    while IFS= read -r line; do
        if [ -n "$line" ] && [ -e "$CACHE_BASE$line" ]; then
            printf '%s\n' "$CACHE_BASE$line"
        else
            printf '%s\n' "$line"
        fi
    done <<< "$nix_output"
fi

exit $nix_rc
