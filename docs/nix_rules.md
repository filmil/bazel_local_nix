<!-- Generated with Stardoc: http://skydoc.bazel.build -->



<a id="nix_package"></a>

## nix_package

<pre>
load("@rules_nix//:nix_rules.bzl", "nix_package")

nix_package(<a href="#nix_package-name">name</a>, <a href="#nix_package-installable">installable</a>)
</pre>

Builds a Nix installable into a self-contained, relocatable <name>.tar.gz bundle.

**ATTRIBUTES**


| Name  | Description | Type | Mandatory | Default |
| :------------- | :------------- | :------------- | :------------- | :------------- |
| <a id="nix_package-name"></a>name |  A unique name for this target.   | <a href="https://bazel.build/concepts/labels#target-names">Name</a> | required |  |
| <a id="nix_package-installable"></a>installable |  Nix installable to build (a pinned flake reference).   | String | optional |  `"github:NixOS/nixpkgs/b134951a4c9f3c995fd7be05f3243f8ecd65d798#hello"`  |


<a id="nix_toolchain"></a>

## nix_toolchain

<pre>
load("@rules_nix//:nix_rules.bzl", "nix_toolchain")

nix_toolchain(<a href="#nix_toolchain-name">name</a>, <a href="#nix_toolchain-bundle">bundle</a>)
</pre>

Extracts a nix_package bundle into a usable directory tree.

**ATTRIBUTES**


| Name  | Description | Type | Mandatory | Default |
| :------------- | :------------- | :------------- | :------------- | :------------- |
| <a id="nix_toolchain-name"></a>name |  A unique name for this target.   | <a href="https://bazel.build/concepts/labels#target-names">Name</a> | required |  |
| <a id="nix_toolchain-bundle"></a>bundle |  A nix_package output (.tar.gz) to extract.   | <a href="https://bazel.build/concepts/labels">Label</a> | required |  |


