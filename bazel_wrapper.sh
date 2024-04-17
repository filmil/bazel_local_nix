#! /bin/bash
set -x
set -e

# A wrapper script for bazel or bazelisk, which sets up the build environment
# to work with a local hermetic installation of nix.
# Started by bazel/bazelisk instead of ${BAZEL_REAL}

unshare --user --pid echo || (
    echo "Looks like this user is not allowed to make chrooted environments."
    echo "unfortunately, this is where it ends."
    exit 1
)

# Script directory.
# https://stackoverflow.com/questions/59895
readonly _script_dir=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

readonly _this_script="${0}"

readonly _arch_dir="$(uname -m)-$(uname -s)"
readonly _output_user_root="${HOME}/.cache/bazel/_bazel_${USER}"
readonly _nix_install="${_output_user_root}/nix_install"
readonly _sha256="$(sha256sum ${_this_script})"
readonly _install_filename="${_nix_install}/created"
readonly _nix_portable="${INFO_WORKSPACE}/${NIX_PORTABLE_BINARY}"

function install_nix {
    # Not installed, go install it.
    echo "=== Nix repo is not installed for bazel. This will be done now."
    echo "=== Please be patient, it will take a while. An Internet connection"
    echo "=== is required."
    mkdir -p "${_nix_install}"
    echo "${_sha256}" > "${_install_filename}"
}


if [[ ! -f "${_install_filename}" ]]; then
    install_nix
else
    readonly _saved_sha256="$(cat ${_install_filename})"
    if [[ "${_saved_sha256}" != "${_sha256}" ]]; then
        install_nix
    fi
fi

# TODO: fmil - This displaces the bazel cache, which is not expected. I would
# prefer that it does not. XDG_CACHE_HOME is not honored by bazel until 7.2.0
# :(
readonly _cmdline="\
    if [[ -d /nix/store ]]; then \
      ${BAZEL_REAL} ${@}; \
    else 
        echo /nix/store not present ; \
    fi"

env NP_LOCATION="${_nix_install}" \
		NP_RUNTIME=bwrap \
	"${_nix_portable}" nix-shell --run "${_cmdline}"

