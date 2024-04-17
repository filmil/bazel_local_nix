#! /bin/bash
set -x

readonly _tool_addresses_script="${1}"
readonly _bazel_stub_script="${2}"

readonly _bazel_source_workspace="${BUILD_WORKSPACE_DIRECTORY}"
readonly _thisdir="${PWD}"

cd "${_bazel_source_workspace}"

readonly _bazel_workspace="$(bazel info output_base)"

mkdir -p "${_bazel_source_workspace}/tools"

readonly _tools_addresses="tools/tool_addresses.sh"
cp "${_thisdir}/${_tool_addresses_script}" "${_tools_addresses}"
chmod ug+w "${_tools_addresses}"

readonly _tools_bazel="tools/bazel"
cp "${_thisdir}/${_bazel_stub_script}" "${_tools_bazel}"
echo "INFO_WORKSPACE=${_bazel_workspace}" >> "${_tools_addresses}"

