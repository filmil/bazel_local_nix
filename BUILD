sh_binary(
    name = "install",
    srcs = [ "install.sh", ], 

    args = [
        "$(location :tool_addresses)",
    ],
    data = [
        ":tool_addresses",
    ],
)

genrule(
    name = "tool_addresses",
    outs = [ "tool_addresses.sh" ],
    cmd = """
cat <<EOF
# Generated file.
# You can edit, but you can revert to the original version by:
#    bazel run @bazel_local_nix//:install
NIX_PORTABLE_BINARY="$(location :@nix_portable//file)"
BAZEL_WRAPPER="$(location :@nix_portable//file)"
EOF > 
    """,
    executable = True,
    data = [
        "@nix_portable//file",
        "//tools:bazel_wrapper"
    ],
)

sh_binary(
    "bazel_stub",
    srcs = [ "bazel_stub.sh" ],
)
