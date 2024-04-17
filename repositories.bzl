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
        sha256 = "b409c55904c909ac3aeda3fb1253319f86a89ddd1ba31a5dec33d4a06414c72a",
        executable = True,
        downloaded_file_path = "nix-portable",
    )
