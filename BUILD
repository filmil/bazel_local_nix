sh_binary(
    name = "install",
    srcs = [ "install.sh", ],

    args = [
        "$(location :bazel_stub)",
        "$(location :bazel_wrapper)",
        "$(location @nix_portable//file)",
        "$(location :nix_cmdline)",
    ],
    data = [
        ":bazel_stub",
        ":bazel_wrapper",
        "@nix_portable//file",
        ":nix_cmdline",
    ],
)

sh_binary(
    name = "bazel_stub",
    srcs = [ "bazel" ],
)

sh_binary(
    name = "bazel_wrapper",
    srcs = [ "bazel_wrapper.sh", ],
    visibility = [ "//visibility:public", ],
)

sh_binary(
    name = "nix_cmdline",
    srcs = [ "nix_cmdline.sh", ],
    visibility = [ "//visibility:public", ],
)

