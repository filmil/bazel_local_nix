#! /bin/bash
set -x

env

# This file "just" forwards to the actual binary.

# Script directory.
# https://stackoverflow.com/questions/59895
readonly _script_dir=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

source "${_script_dir}/tool_addresses.sh"

export BAZEL_REAL NIX_PORTABLE_BINARY INFO_WORKSPACE

"${INFO_WORKSPACE}/${BAZEL_WRAPPER}" "${@}"

