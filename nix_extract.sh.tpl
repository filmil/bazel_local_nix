#!/bin/bash
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
