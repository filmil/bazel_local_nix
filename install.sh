#! /bin/bash

readonly _nix_portable_binary="$(bazel info workspace)/${1}"

echo "nix-portable-binary=${_nix_portable_binary}"

