<!-- Generated with Stardoc: http://skydoc.bazel.build -->



<a id="nix_cc"></a>

## nix_cc

<pre>
nix_cc = use_extension("@rules_nix//:extensions.bzl", "nix_cc")
nix_cc.configure(<a href="#nix_cc.configure-name">name</a>, <a href="#nix_cc.configure-attribute">attribute</a>, <a href="#nix_cc.configure-nixpkgs">nixpkgs</a>)
</pre>

Module extension that configures a Nix-backed C/C++ toolchain.

Allows configuring a compiler from nixpkgs (e.g. gcc, clang) which will
be automatically registered as a Bazel cc_toolchain.


**TAG CLASSES**

<a id="nix_cc.configure"></a>

### configure

**Attributes**

| Name  | Description | Type | Mandatory | Default |
| :------------- | :------------- | :------------- | :------------- | :------------- |
| <a id="nix_cc.configure-name"></a>name |  Name of the generated toolchain repository.   | <a href="https://bazel.build/concepts/labels#target-names">Name</a> | optional |  `"nix_cc_toolchain"`  |
| <a id="nix_cc.configure-attribute"></a>attribute |  nixpkgs attribute providing the C/C++ compiler.   | String | optional |  `"gcc"`  |
| <a id="nix_cc.configure-nixpkgs"></a>nixpkgs |  Pinned nixpkgs flake reference (without the #attribute).   | String | optional |  `"github:NixOS/nixpkgs/b134951a4c9f3c995fd7be05f3243f8ecd65d798"`  |


<a id="nix_gnat"></a>

## nix_gnat

<pre>
nix_gnat = use_extension("@rules_nix//:extensions.bzl", "nix_gnat")
nix_gnat.configure(<a href="#nix_gnat.configure-name">name</a>, <a href="#nix_gnat.configure-attribute">attribute</a>, <a href="#nix_gnat.configure-nixpkgs">nixpkgs</a>)
</pre>

Module extension that configures a Nix-backed GNAT toolchain.


**TAG CLASSES**

<a id="nix_gnat.configure"></a>

### configure

**Attributes**

| Name  | Description | Type | Mandatory | Default |
| :------------- | :------------- | :------------- | :------------- | :------------- |
| <a id="nix_gnat.configure-name"></a>name |  Name of the generated toolchain repository.   | <a href="https://bazel.build/concepts/labels#target-names">Name</a> | optional |  `"nix_gnat_toolchain"`  |
| <a id="nix_gnat.configure-attribute"></a>attribute |  nixpkgs attribute providing the GNAT compiler.   | String | optional |  `"gnat"`  |
| <a id="nix_gnat.configure-nixpkgs"></a>nixpkgs |  Pinned nixpkgs flake reference (without the #attribute).   | String | optional |  `"github:NixOS/nixpkgs/b134951a4c9f3c995fd7be05f3243f8ecd65d798"`  |


