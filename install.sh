#! /bin/bash

readonly _bazel_workspace="$(bazel info workspace)"

mkdir -p "${_bazel_workspace}/tools"

readonly _tool_addresses_script="${1}"
readonly _bazel_stub_script="${2}"

cp "${_tool_addresses_script}" "${_bazel_workspace}/tools/tool_addresses.sh"
cp "${_bazel_stub_script}" "${_bazel_workspace}/tools/bazel"

