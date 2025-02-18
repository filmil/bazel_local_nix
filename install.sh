#! /bin/bash
set -eo pipefail
set -x

# Installs the bazel_local_nix tools into the current bazel repository.

if [[ "${BUILD_WORKSPACE_DIRECTORY}" == "" ]]; then
    echo "This file is intended to be run as `bazel run @bazel_local_nix//:install`"
    exit 1
fi

# This one gets installed into //tools of the main repo.
readonly _bazel_stub_script="${1}"

# This is the actual script, and gets installed into _scripts_dir below.
readonly _bazel_wrapper_script="${2}"

# The nix-portable binary
readonly _nix_portable_binary="${3}"

readonly _cmd="${4}"

readonly _bazel_source_workspace="${BUILD_WORKSPACE_DIRECTORY}"
readonly _thisdir="${PWD}"

readonly _output_user_root="${HOME}/.cache/bazel/_bazel_${USER}"
readonly _nix_install="${_output_user_root}/nix_install"

# Install all the scripts here. Otherwise, it's onerous to install in per-repo
# directory. This may or may not be a bug.
readonly _scripts_dir="${_nix_install}/scripts_dir"
mkdir -p ${_scripts_dir}

mkdir -p "${_bazel_source_workspace}/tools"

if [[ "${_cmd}" != "noscript" ]]; then
    readonly _tools_bazel="tools/bazel"
    cp "${_bazel_stub_script}" "${_bazel_source_workspace}/tools/bazel"
    chmod a+x "${_bazel_source_workspace}/tools/bazel"
fi

cp "${_bazel_wrapper_script}" "${_scripts_dir}"

# It is important that this binary's name remains nix-portable.
cp "${_nix_portable_binary}" "${_scripts_dir}"

