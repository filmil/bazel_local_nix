# SPDX-License-Identifier: Apache-2.0
# nix_bootstrap.bzl
#
# Repository rule that fetches a pinned, relocatable Nix binary release and
# materializes the bwrap runtime wrapper. This is the Nix analog of
# rules_guix's guix_bootstrap rule; unlike Guix it does not rely on a
# system daemon -- single-user Nix operates on the store directly.

# Pinned Nix release. Bumping these two values (and re-running) is the only
# change required to track a new Nix; the wrapper discovers binaries in a
# version-agnostic way (see nix_wrapper.sh.tpl).
NIX_VERSION = "2.24.10"
NIX_SHA256 = "ec1023e4c0e01da4bbec64c19e9a2bc94d36feae421402abbf3a2db848a1c6b5"

_BOOTSTRAP_BUILD = """
exports_files(["nix_wrapper.sh", "nix_run_shim.sh"])
filegroup(
    name = "nix_binaries",
    srcs = glob(["nix-*-x86_64-linux/**"]),
    visibility = ["//visibility:public"],
)
"""

def _nix_bootstrap_impl(repository_ctx):
    nix_url = "https://releases.nixos.org/nix/nix-{v}/nix-{v}-x86_64-linux.tar.xz".format(
        v = NIX_VERSION,
    )
    repository_ctx.download(
        url = nix_url,
        output = "nix.tar.xz",
        sha256 = NIX_SHA256,
    )

    res = repository_ctx.execute(["tar", "xf", "nix.tar.xz"])
    if res.return_code != 0:
        fail("nix_bootstrap: tar xf failed:\n" + res.stderr)
    repository_ctx.execute(["rm", "nix.tar.xz"])

    # The wrapper and run-shim are maintained as real shell files (so they stay
    # lintable and free of escaping); we just copy them into place. They live
    # in the bootstrap repo -- not the rules_nix root package -- so that
    # nix_package's implicit deps don't force downstream modules to load the
    # root BUILD (which pulls in dev-only deps like @stardoc).
    repository_ctx.template(
        "nix_wrapper.sh",
        repository_ctx.attr._wrapper,
        executable = True,
    )
    repository_ctx.template(
        "nix_run_shim.sh",
        repository_ctx.attr._run_shim,
        executable = True,
    )
    repository_ctx.file("BUILD", content = _BOOTSTRAP_BUILD)

nix_bootstrap = repository_rule(
    implementation = _nix_bootstrap_impl,
    doc = """Repository rule that fetches a pinned Nix binary release.

Unpacks the official Nix binary release and materializes the bwrap
wrapper script ('nix_wrapper.sh') required by nix_package.
""",
    attrs = {
        "_wrapper": attr.label(
            doc = "Template for the nix_wrapper script.",
            default = Label("//:nix_wrapper.sh.tpl"),
            allow_single_file = True,
        ),
        "_run_shim": attr.label(
            doc = "Template for the run-shim script.",
            default = Label("//:nix_run_shim.sh"),
            allow_single_file = True,
        ),
    },
)
