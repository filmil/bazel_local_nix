load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_file")
load(
    "@bazel_tools//tools/build_defs/repo:utils.bzl",
    "maybe",
)


def bazel_local_nix_dependencies():
    maybe(
        repo_rule = http_file,
        name = "nix_portable",
        # This is x86_64 on Linux only.
        url = "https://github.com/DavHau/nix-portable/releases/download/v012/nix-portable-x86_64",
        sha256 = "",
        executable = True,
    )