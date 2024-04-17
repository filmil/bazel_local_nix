sh_binary(
    name = "install",
    srcs = [ "install.sh", ], 

    args = [
        "$(location :tool_addresses)",
        "$(location :bazel_stub)",
    ],
    data = [
        ":tool_addresses",
        ":bazel_stub",
    ],
)

genrule(
    name = "tool_addresses",
    outs = [ "tool_addresses.sh" ],
    cmd = """
cat <<EOF > $@
# THIS IS A GENERATED FILE.
# You can edit, but you can also revert to the original version by running:
#    bazel run @bazel_local_nix//:install

NIX_PORTABLE_BINARY="$(location @nix_portable//file)"
BAZEL_WRAPPER="$(location //:bazel_wrapper)"

EOF
    """,
    executable = True,
    tools = [
        "@nix_portable//file",
        "//:bazel_wrapper"
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

