<!-- Generated with Stardoc: http://skydoc.bazel.build -->



<a id="nix_cc_toolchain_config"></a>

## nix_cc_toolchain_config

<pre>
load("@rules_nix//:nix_cc.bzl", "nix_cc_toolchain_config")

nix_cc_toolchain_config(<a href="#nix_cc_toolchain_config-name">name</a>, <a href="#nix_cc_toolchain_config-builtin_include_directories">builtin_include_directories</a>)
</pre>

Generates a cc_toolchain_config for a Nix-backed C/C++ toolchain.

Example:
    ```starlark
    load("@rules_nix//:nix_cc.bzl", "nix_cc_toolchain_config")

    nix_cc_toolchain_config(
        name = "nix_cc_config",
        builtin_include_directories = ["/nix/store"],
    )
    ```

**ATTRIBUTES**


| Name  | Description | Type | Mandatory | Default |
| :------------- | :------------- | :------------- | :------------- | :------------- |
| <a id="nix_cc_toolchain_config-name"></a>name |  A unique name for this target.   | <a href="https://bazel.build/concepts/labels#target-names">Name</a> | required |  |
| <a id="nix_cc_toolchain_config-builtin_include_directories"></a>builtin_include_directories |  Directories allowed for C++ builtin includes.   | List of strings | optional |  `["/nix/store"]`  |


<a id="nix_cc_repo"></a>

## nix_cc_repo

<pre>
load("@rules_nix//:nix_cc.bzl", "nix_cc_repo")

nix_cc_repo(<a href="#nix_cc_repo-name">name</a>, <a href="#nix_cc_repo-installable">installable</a>)
</pre>

Realizes a Nix-backed C/C++ toolchain into an external repository.

Realizes the full closure of the compiler from nixpkgs, copies it into
the external repository, and generates a cc_toolchain definition.

Example:
    ```starlark
    load("@rules_nix//:nix_cc.bzl", "nix_cc_repo")

    nix_cc_repo(
        name = "nix_cc_toolchain",
        installable = "github:NixOS/nixpkgs/nixos-23.11#gcc",
    )
    ```

**ATTRIBUTES**


| Name  | Description | Type | Mandatory | Default |
| :------------- | :------------- | :------------- | :------------- | :------------- |
| <a id="nix_cc_repo-name"></a>name |  A unique name for this repository.   | <a href="https://bazel.build/concepts/labels#target-names">Name</a> | required |  |
| <a id="nix_cc_repo-installable"></a>installable |  Nix installable providing the C/C++ compiler (e.g. 'nixpkgs#gcc').   | String | required |  |


