#! /bin/bash
set -eo pipefail
#set -x

if [[ "${BAZEL_LOCAL_NIX_DEBUG}" != "" ]]; then
    echo "=== Using bazel wrapper at //tools/bazel"
fi

# In the exceptional case where the user wants to reinstall local nix rules,
# forward to BAZEL_REAL.
if [[ "${@}" == "--max_idle_secs=1 run @bazel_local_nix//:install" ]]; then
    echo "=== Installation forwarded to real bazel, this must be done first."
    exec "${BAZEL_REAL}" $@
fi

# A wrapper script for bazel or bazelisk, which sets up the build environment
# to work with a local hermetic installation of nix.
# Started by bazel/bazelisk instead of ${BAZEL_REAL}

# Script directory.
# https://stackoverflow.com/questions/59895
readonly _script_dir=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

readonly _this_script="${0}"

readonly _output_user_root="${HOME}/.cache/bazel/_bazel_${USER}"
readonly _nix_install="${_output_user_root}/nix_install"
readonly _sha256="$(sha256sum ${_this_script})"
readonly _install_filename="${_nix_install}/created"
readonly _nix_portable="${NIX_PORTABLE_BINARY}"

function install_nix {
    # Not installed, go install it.
    echo "==="
    echo "=== Nix repo is not installed for bazel. This will be done now."
    echo "=== The installation should be one time only, or in some cases rare."
    echo "==="
    echo "=== Please be patient, it will take a while. An Internet connection"
    echo "=== is required."
    echo "==="
    echo "=== Also, the nix files such as flake.nix MUST be merged into your repo."
    echo "=== Otherwise, bizarre errros may ensue."
    echo "==="
    mkdir -p "${_nix_install}"
    echo "${_sha256}" > "${_install_filename}"
}


if [[ ! -f "${_install_filename}" ]]; then
    install_nix
else
    readonly _saved_sha256="$(cat ${_install_filename})"
    if [[ "${_saved_sha256}" != "${_sha256}" ]]; then
        echo "=== It seems that ephemeral nix install changed"
        echo "=== Repeating install."
        install_nix
    fi
fi

readonly _cmdline="${_nix_install}/scripts_dir/nix_cmdline ${@}"
env NP_LOCATION="${_nix_install}" "${_nix_portable}" \
    nix-shell --run "${_cmdline}"

