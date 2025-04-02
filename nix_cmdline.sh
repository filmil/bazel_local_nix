#! /bin/bash
# This script is executed under nix shell.

# The PATH should be a nix enabled path.
if [[ -d "/nix/store" ]]; then
    env PATH=$PATH ${BAZEL_REAL} ${@}
else
    echo "/nix/store is not present, but should be."
fi
