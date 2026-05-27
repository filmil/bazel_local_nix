<!-- SPDX-License-Identifier: Apache-2.0 -->

# Integration: Nix-provided compiler (toolchain placeholder)

A standalone Bazel module that obtains a C/C++ compiler (`nixpkgs#gcc`) as a
relocatable bundle via `rules_nix` and runs it through the bundle's run-shim.

This directory is the home of **upcoming future work**: turning the Nix `gcc`
into a real Bazel `cc_toolchain` configured in `MODULE.bazel` (in the spirit of
[`tweag/rules_nixpkgs`](https://github.com/tweag/rules_nixpkgs); see rules_nix
spec FUT-2). Once that lands, `hello.cc` will be built with a normal
`cc_binary` resolved against the Nix-backed toolchain.

For now the example only demonstrates obtaining and invoking the compiler:

```sh
bazel build //:compiler_version
cat bazel-bin/gcc_version.txt   # -> g++ (GCC) ...
```

The targets are tagged `manual` (and `requires-network` / `no-sandbox` /
`local`) because they reach `cache.nixos.org` and run Nix under `bwrap`.
