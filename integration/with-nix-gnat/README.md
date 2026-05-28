<!-- SPDX-License-Identifier: Apache-2.0 -->

# Integration: Nix-backed C/C++ toolchain

A standalone Bazel module that configures a **Nix-backed `cc_toolchain`** in
`MODULE.bazel` (via the `rules_nix` `nix_cc` module extension) and compiles
`hello.cc` with it using an ordinary `cc_binary`. This is the rules_nix analog
of [`tweag/rules_nixpkgs`](https://github.com/tweag/rules_nixpkgs), adapted to
the host-Nix-free model: the nixpkgs `gcc` closure is realized once into a
generated repository, and each cc tool runs through a `bwrap` wrapper that
overlays that closure at `/nix/store`.

Because the compiler runs under `bwrap` (a user namespace, which cannot nest
inside Bazel's sandbox), cc actions use the local spawn strategy — see
`.bazelrc` (`build --spawn_strategy=local`).

```sh
bazel build //:hello
```

The resulting `bazel-bin/hello` links against `/nix/store`, so it runs on a
host without `/nix` only under `bwrap` with the toolchain store bound at
`/nix/store`:

```sh
repo="$(bazel info output_base)/external/rules_nix++nix_cc+nix_cc_toolchain"
bwrap --tmpfs / --ro-bind /usr /usr --ro-bind /bin /bin \
      --ro-bind-try /lib /lib --ro-bind-try /lib64 /lib64 \
      --dev /dev --proc /proc --tmpfs /tmp \
      --bind "$repo/nix/store" /nix/store \
      --bind "$(bazel info bazel-bin)/hello" /hello /hello
# -> Hello world!
```

The `//:hello` target is tagged `manual` (it reaches the network on first build
and runs Nix under `bwrap`), so it is excluded from `bazel build/test //...`.
