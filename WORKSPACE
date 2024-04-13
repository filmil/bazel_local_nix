workspace(name = "bazel-nix-flakes-example")
load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_archive")

http_archive(
    name = "rules_cc",
    sha256 = "4dccbfd22c0def164c8f47458bd50e0c7148f3d92002cdb459c2a96a68498241",
    urls = [
        "https://github.com/bazelbuild/rules_cc/releases/download/0.0.1/rules_cc-0.0.1.tar.gz",
    ],
)

load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_archive")


######################
# Tweag Nix Support
######################

# Replace with http_archive: https://github.com/tweag/rules_nixpkgs/#setup
http_archive(
    name = "io_tweag_rules_nixpkgs",
    strip_prefix = "rules_nixpkgs-126e9f66b833337be2c35103ce46ab66b4e44799",
    urls = ["https://github.com/tweag/rules_nixpkgs/archive/126e9f66b833337be2c35103ce46ab66b4e44799.tar.gz"],
    sha256 = "480df4a7777a5e3ee7a755ab38d18ecb3ddb7b2e2435f24ad2037c1b084faa65",
)

load("@io_tweag_rules_nixpkgs//nixpkgs:repositories.bzl", "rules_nixpkgs_dependencies")
rules_nixpkgs_dependencies()

# Define nixpkgs version using the flakes lock file.
load("@io_tweag_rules_nixpkgs//nixpkgs:nixpkgs.bzl", "nixpkgs_local_repository")
nixpkgs_local_repository(
    name = "nixpkgs",
    nix_flake_lock_file = "//:flake.lock",
    nix_file_deps = ["//:flake.lock"],
)

# Configure the C++ toolchain
load("@io_tweag_rules_nixpkgs//nixpkgs:nixpkgs.bzl", "nixpkgs_cc_configure")
nixpkgs_cc_configure(
    name = "nixpkgs_config_cc",
    repository = "@nixpkgs",
    attribute_path = "clang_13",
)

load("@rules_cc//cc:repositories.bzl", "rules_cc_dependencies", "rules_cc_toolchains")

rules_cc_dependencies()

rules_cc_toolchains()

