<!-- Generated with Stardoc: http://skydoc.bazel.build -->



<a id="nix_bootstrap"></a>

## nix_bootstrap

<pre>
load("@rules_nix//:nix_bootstrap.bzl", "nix_bootstrap")

nix_bootstrap(<a href="#nix_bootstrap-name">name</a>)
</pre>

Repository rule that fetches a pinned Nix binary release.

Unpacks the official Nix binary release and materializes the bwrap
wrapper script ('nix_wrapper.sh') required by nix_package.

**ATTRIBUTES**


| Name  | Description | Type | Mandatory | Default |
| :------------- | :------------- | :------------- | :------------- | :------------- |
| <a id="nix_bootstrap-name"></a>name |  A unique name for this repository.   | <a href="https://bazel.build/concepts/labels#target-names">Name</a> | required |  |


