<!-- Generated with Stardoc: http://skydoc.bazel.build -->



<a id="self_extracting_binary"></a>

## self_extracting_binary

<pre>
load("@rules_nix//:elf_bundle.bzl", "self_extracting_binary")

self_extracting_binary(<a href="#self_extracting_binary-name">name</a>, <a href="#self_extracting_binary-binary">binary</a>)
</pre>

Creates a self-extracting archive of a binary and its shared library dependencies.

Traverses the transitive shared library dependencies of the given binary
using 'ldd', bundles them together with a custom dynamic linker, patches
their RPATHs using 'patchelf', and prepends a self-extracting shell header.

**ATTRIBUTES**


| Name  | Description | Type | Mandatory | Default |
| :------------- | :------------- | :------------- | :------------- | :------------- |
| <a id="self_extracting_binary-name"></a>name |  A unique name for this target.   | <a href="https://bazel.build/concepts/labels#target-names">Name</a> | required |  |
| <a id="self_extracting_binary-binary"></a>binary |  The binary target to bundle.   | <a href="https://bazel.build/concepts/labels">Label</a> | required |  |


