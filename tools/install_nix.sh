#!/bin/sh

# This script installs the Nix package manager on your system by
# downloading a binary distribution and running its installer script
# (which in turn creates and populates /nix).

{ # Prevent execution if this script was only partially downloaded
oops() {
    echo "$0:" "$@" >&2
    exit 1
}

umask 0022

tmpDir="$(mktemp -d -t nix-binary-tarball-unpack.XXXXXXXXXX || \
          oops "Can't create temporary directory for downloading the Nix binary tarball")"
cleanup() {
    rm -rf "$tmpDir"
}
trap cleanup EXIT INT QUIT TERM

require_util() {
    command -v "$1" > /dev/null 2>&1 ||
        oops "you do not have '$1' installed, which I need to $2"
}

case "$(uname -s).$(uname -m)" in
    Linux.x86_64)
        hash=69f4c7efe480fac3bde1bc765a922f439445e02fc06c93020e82b52da35dea06
        path=q3dsj7znm02b1yjay3335crsml8rxq77/nix-2.21.1-x86_64-linux.tar.xz
        system=x86_64-linux
        ;;
    Linux.i?86)
        hash=516835cabb09024409e46765cc2663a6d31847925d43cb29a36313ed690b5be2
        path=x611bcqzxx8705kn66pzl8xbgb0ixkyq/nix-2.21.1-i686-linux.tar.xz
        system=i686-linux
        ;;
    Linux.aarch64)
        hash=35bd457dd86a1a517a71539a70c2ebd44ffe05fac765d425a2e364488819ee71
        path=himjmci90a53bi7xnxh5xqxyxzyglw98/nix-2.21.1-aarch64-linux.tar.xz
        system=aarch64-linux
        ;;
    Linux.armv6l)
        hash=825e4be5838d21991962358c0d74729d510059b8a6f69f72ea7f54a79d9e257b
        path=6ryl91w86jyb5ylrg28s1rfbz3mmpgj2/nix-2.21.1-armv6l-linux.tar.xz
        system=armv6l-linux
        ;;
    Linux.armv7l)
        hash=ff4db5b164fed30b98f1474ad5ae2eb9240e01aa86c3a443440d78fe4ba3d95a
        path=lr0wbjvmi8x52dycll7f35sf9z1igpwb/nix-2.21.1-armv7l-linux.tar.xz
        system=armv7l-linux
        ;;
    Darwin.x86_64)
        hash=8b47944a5d1e8d334a998168e336ef65f6510876a3081c01f3e4c0cc40008ab9
        path=7apfm7ys1f2vlrm9m7axjqrzbc79f07f/nix-2.21.1-x86_64-darwin.tar.xz
        system=x86_64-darwin
        ;;
    Darwin.arm64|Darwin.aarch64)
        hash=c98fa99ea74646e2240bb68953d09903d7b63487cc2a35c371f30794af39a59a
        path=0janb8lm0i6w1897lr0bkqrxrpncx57m/nix-2.21.1-aarch64-darwin.tar.xz
        system=aarch64-darwin
        ;;
    *) oops "sorry, there is no binary distribution of Nix for your platform";;
esac

# Use this command-line option to fetch the tarballs using nar-serve or Cachix
if [ "${1:-}" = "--tarball-url-prefix" ]; then
    if [ -z "${2:-}" ]; then
        oops "missing argument for --tarball-url-prefix"
    fi
    url=${2}/${path}
    shift 2
else
    url=https://releases.nixos.org/nix/nix-2.21.1/nix-2.21.1-$system.tar.xz
fi

tarball=$tmpDir/nix-2.21.1-$system.tar.xz

require_util tar "unpack the binary tarball"
if [ "$(uname -s)" != "Darwin" ]; then
    require_util xz "unpack the binary tarball"
fi

if command -v curl > /dev/null 2>&1; then
    fetch() { curl --fail -L "$1" -o "$2"; }
elif command -v wget > /dev/null 2>&1; then
    fetch() { wget "$1" -O "$2"; }
else
    oops "you don't have wget or curl installed, which I need to download the binary tarball"
fi

echo "downloading Nix 2.21.1 binary tarball for $system from '$url' to '$tmpDir'..."
fetch "$url" "$tarball" || oops "failed to download '$url'"

if command -v sha256sum > /dev/null 2>&1; then
    hash2="$(sha256sum -b "$tarball" | cut -c1-64)"
elif command -v shasum > /dev/null 2>&1; then
    hash2="$(shasum -a 256 -b "$tarball" | cut -c1-64)"
elif command -v openssl > /dev/null 2>&1; then
    hash2="$(openssl dgst -r -sha256 "$tarball" | cut -c1-64)"
else
    oops "cannot verify the SHA-256 hash of '$url'; you need one of 'shasum', 'sha256sum', or 'openssl'"
fi

if [ "$hash" != "$hash2" ]; then
    oops "SHA-256 hash mismatch in '$url'; expected $hash, got $hash2"
fi

unpack=$tmpDir/unpack
mkdir -p "$unpack"
tar -xJf "$tarball" -C "$unpack" || oops "failed to unpack '$url'"

script=$(echo "$unpack"/*/install)

[ -e "$script" ] || oops "installation script is missing from the binary tarball!"
export INVOKED_FROM_INSTALL_IN=1
"$script" "$@"

} # End of wrapping
