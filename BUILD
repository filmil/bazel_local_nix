sh_binary(
    name = "install",
    srcs = [ "install.sh", ], 

    args = [
        "$(location :bazel_stub)",
        "$(location :bazel_wrapper)",
        "$(location @nix_portable//file)",
    ],
    data = [
        ":bazel_stub",
        ":bazel_wrapper",
        "@nix_portable//file",
    ],
)

sh_binary(
    name = "bazel_stub",
    srcs = [ "bazel_stub.sh" ],
)

sh_binary(
    name = "bazel_wrapper",
    srcs = [ "bazel_wrapper.sh", ], 
    visibility = [ "//visibility:public", ],
)

