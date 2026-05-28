<!-- Generated with Stardoc: http://skydoc.bazel.build -->



<a id="nix_package"></a>

## nix_package

<pre>
load("@rules_nix//:nix_rules.bzl", "nix_package")

nix_package(<a href="#nix_package-name">name</a>, <a href="#nix_package-installable">installable</a>)
</pre>

Builds a Nix installable into a self-contained, relocatable <name>.tar.gz bundle.

The produced bundle contains the full runtime closure of the installable,
with absolute /nix/store paths preserved. It also includes relocatable
bin/ shims and a bundled static bwrap that allow running the bundled
binaries on hosts without a local /nix/store or a host-provided bwrap.

Example:
    ```starlark
    load("@rules_nix//:nix_rules.bzl", "nix_package")

    nix_package(
        name = "hello_pkg",
        installable = "nixpkgs#hello",
    )
    ```

**ATTRIBUTES**


| Name  | Description | Type | Mandatory | Default |
| :------------- | :------------- | :------------- | :------------- | :------------- |
| <a id="nix_package-name"></a>name |  A unique name for this target.   | <a href="https://bazel.build/concepts/labels#target-names">Name</a> | required |  |
| <a id="nix_package-installable"></a>installable |  Nix installable to build (a pinned flake reference, e.g. 'nixpkgs#hello').   | String | optional |  `"github:NixOS/nixpkgs/b134951a4c9f3c995fd7be05f3243f8ecd65d798#hello"`  |


<a id="nix_toolchain"></a>

## nix_toolchain

<pre>
load("@rules_nix//:nix_rules.bzl", "nix_toolchain")

nix_toolchain(<a href="#nix_toolchain-name">name</a>, <a href="#nix_toolchain-bundle">bundle</a>)
</pre>

Extracts a nix_package bundle into a usable directory tree.

Downstream rules can then invoke binaries from the extracted tree
(e.g. '<extracted_dir>/bin/hello').

Example:
    ```starlark
    load("@rules_nix//:nix_rules.bzl", "nix_package", "nix_toolchain")

    nix_package(
        name = "hello_pkg",
        installable = "nixpkgs#hello",
    )

    nix_toolchain(
        name = "hello_toolchain",
        bundle = ":hello_pkg",
    )
    ```

**ATTRIBUTES**


| Name  | Description | Type | Mandatory | Default |
| :------------- | :------------- | :------------- | :------------- | :------------- |
| <a id="nix_toolchain-name"></a>name |  A unique name for this target.   | <a href="https://bazel.build/concepts/labels#target-names">Name</a> | required |  |
| <a id="nix_toolchain-bundle"></a>bundle |  A nix_package output (.tar.gz) to extract.   | <a href="https://bazel.build/concepts/labels">Label</a> | required |  |


