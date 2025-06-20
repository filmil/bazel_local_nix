# Hermetic, ephemeral and reproducible ("HER") Bazel builds [![Test status](https://github.com/filmil/bazel_local_nix/workflows/Test/badge.svg)](https://github.com/filmil/bazel_local_nix/workflows/Test/badge.svg)

This is an experiment in fully hermetic, but also self-installing [nix][nx]
based hermetic bazel build.

I call it a HER build, which stands for:

*   **Hermetic:** Builds are insensitive to the host system's libraries and tools. All dependencies are explicitly declared and managed by Nix.
*   **Ephemeral:** The Nix environment, which provides all build dependencies, is set up on-the-fly for each build and does not require a persistent system-wide Nix installation. It's temporary and isolated.
*   **Reproducible:** Given the same inputs (source code, dependency versions), the build will always produce the exact same outputs, regardless of where or when it's run.

The key advantages of this approach are consistency across developer machines and CI, increased reliability of builds, easier onboarding for new developers (as they don't need to manually configure a Nix environment), and no pollution of the global system with project-specific dependencies.

[nx]: https://nixos.org

Sadly, it only works on Linux today, as some essential parts are Linux-specific.
So if you are on Windows, Mac, or Fuchsia, this solution is not currently applicable.

## Understanding Bazel and Nix in this Context

This project leverages both Bazel and Nix to achieve its goals. Here's a brief overview:

*   **Bazel:** Is a powerful build and test tool designed for speed, correctness, and reproducibility, making it excellent for large, complex projects. One of its core strengths is sandboxing, where build steps are isolated from the underlying system to ensure hermeticity.
*   **Nix:** Is a package manager and system configuration tool that excels at creating reproducible software environments. It can manage all project dependencies, from compilers and toolchains to libraries, ensuring that everyone uses the exact same versions. `nixpkgs` is its vast collection of pre-packaged software.

**Why use them together?** This project uses Nix to define and provide a specific, hermetically controlled environment (including all necessary toolchains and libraries). Bazel then runs within this Nix-provided environment to perform the actual build and test operations. The "HER" approach described here enhances this by making the Nix environment itself ephemeral and self-installing, removing the common prerequisite of developers needing to have Nix pre-installed and configured system-wide.

## Table of Contents

* [Understanding Bazel and Nix in this Context](#understanding-bazel-and-nix-in-this-context)
* [The Challenge: Using Nix with Bazel Without System-Wide Installation](#the-challenge-using-nix-with-bazel-without-system-wide-installation)
* [The Solution: Ephemeral, Self-Installing Nix Environments](#the-solution-ephemeral-self-installing-nix-environments)
* [Benefits of this Approach](#benefits-of-this-approach)
* [Bazel's Native Hermeticity vs. HER Builds](#bazels-native-hermeticity-vs-her-builds)
* [Remote Build Compatibility](#remote-build-compatibility)
* [References](#references)
* [Contributing](#contributing)
* [Installation](#installation)
  * [Add the nix files](#add-the-nix-files)
  * [Workspace setup](#workspace-setup)
  * [Modify your `.bazelrc` to add a nix-specific configuration](#modify-your-bazelrc-to-add-a-nix-specific-configuration)
  * [Install `//tools/bazel`](#install-toolsbazel)
  * [Compile](#compile)
* [Maintenance](#maintenance)
  * [Updating `flake.lock`](#updating-flakelock)
* [Troubleshooting](#troubleshooting)
  * [The built binaries can not find shared libraries](#the-built-binaries-can-not-find-shared-libraries)
  * [Other](#other)

## The Challenge: Using Nix with Bazel Without System-Wide Installation

Nix is excellent for creating predictable development environments, which is highly appealing for Bazel builds.
Projects like `rules_nixpkgs` from tweag.io allow Bazel to leverage Nix packages, pulling in dependencies from the vast `nixpkgs` repository.

However, a common hurdle is the requirement for a pre-existing, system-wide Nix installation. This is because traditional Nix usage relies on a `/nix/store` being present on the machine. If a developer doesn't have Nix installed, or cannot/does not want to install it system-wide, they are unable to use these Nix-based Bazel rules. This project aims to remove that barrier.

[nxp]: https://github.com/NixOS/nixpkgs

## The Solution: Ephemeral, Self-Installing Nix Environments

This repository introduces a method where Bazel itself manages the installation of an **ephemeral** Nix store. This means:

*   **No System-Wide Nix Needed:** You do not need to install Nix on your system beforehand. Bazel, through the configurations provided here, will set up a temporary Nix environment for your build.
*   **Automatic Dependency Fetching:** Once the ephemeral Nix is active, Bazel can use `rules_nixpkgs` (or custom rules) to fetch and use dependencies from `nixpkgs` just as it would with a system Nix.
*   **Workspace-Isolated:** The Nix installation is self-contained within your Bazel workspace and does not affect your global system configuration.
*   **Fully Reproducible:** Combining Bazel's reproducibility with Nix's reproducible package management, and an ephemeral setup, results in a highly reliable and reproducible build process.

Essentially, this project makes the Nix environment a self-installing, temporary component of your Bazel build, managed within the workspace.

## Benefits of this Approach

*   **True Hermeticity:** Your build truly depends only on what's defined in the repository.
*   **Simplified Onboarding:** New developers can clone the repository and build without needing to install or configure Nix separately.
*   **No System Pollution:** The Nix environment is temporary and doesn't clutter your system.
*   **Consistency:** Everyone on the team, and CI systems, uses the exact same build environment.
*   **Access to `nixpkgs`:** Leverage the extensive collection of packages available in `nixpkgs` for your Bazel projects.

## Bazel's Native Hermeticity vs. HER Builds

Yes, Bazel itself provides strong sandboxing and aims for hermetic builds. This is effective when all your dependencies are either built with Bazel or can be easily adapted to it.

However, many real-world dependencies are not Bazel-aware. Integrating them often requires significant effort, and some can be problematic within Bazel's sandbox.

Nix helps bridge this gap by providing a predictable, external environment from which Bazel can draw dependencies. This project takes it a step further by making that Nix environment an on-demand, self-contained part of the Bazel workspace, eliminating the need for a pre-installed system Nix. This combination delivers what we call a HER (Hermetic, Ephemeral, Reproducible) build.

## Remote Build Compatibility

I have not tried. I think that it could be made to work. If you are curious to try
making it work for remote builds, do let me know.

## References

See how this is used in the [integration test repo][itr].

[itr]: https://github.com/filmil/bazel_local_nix/tree/main/integration

Read [the article describing the approach][ta].

[ta]: https://hdlfactory.com/post/2024/04/20/nix-bazel-%EF%B8%8F/

I think it is important to note that the contribution of this repository is just in
using a handful of pre-existing tools in what seems to be a novel way, to a useful effect.

## Installation

Installation is done once per repository.
Once the ephemeral nix changes have been committed, any new checkouts will use the nix installation automatically.

This means the person initially setting this up in a repository may need slightly more familiarity with the concepts than subsequent users.

> **Note**: This setup is experimental and not yet considered production-ready. While functional, sharp corners may exist. If you encounter issues, please file a bug with a reproducible test case. Comprehensive documentation is also still under development.

### Add the Nix Configuration Files

The HER setup relies on a few Nix configuration files, typically placed in your repository's root directory. (If you place them elsewhere, you'll need to adjust paths in the subsequent configuration steps, e.g., references to `//:flake.lock`).

1.  **`flake.lock`**: This file pins the exact versions of your Nix dependencies, ensuring reproducibility. It's generated or updated by Nix.
    ```json
    {
      "nodes": {
        "flake-compat": {
          // ... (content specific to your dependencies)
        }
      },
      "root": "root",
      "version": 7
    }
    ```

2.  **`flake.nix`**: This file defines the Nix environment your project needs. You specify required packages (e.g., compilers, tools, libraries) here. Use the [Nixos package search][nps] to find package names.
    ```nix
    {
      description = "C++ environment using Nix flakes";

      inputs = {
        // Consider using a more recent nixpkgs commit or release for latest packages
        nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.05"; // Or your desired nixpkgs version/commit
        flake-compat = {
          url = "github:edolstra/flake-compat"; // Ensure this points to a stable commit if necessary
          flake = false;
        };
        flake-utils.url = "github:numtide/flake-utils"; // Ensure this points to a stable commit if necessary
      };

      outputs = { nixpkgs, flake-utils, ... }:
        flake-utils.lib.eachDefaultSystem (system:
          let
            pkgs = import nixpkgs { inherit system; };
          in
          {
            devShells.default = with pkgs; mkShell {
              name = "flake-example-shell";
              packages = [
                nix       // The Nix package manager itself
                gcc       // Example: C compiler
                gnumake   // Example: Make utility
                bazel_6   // Example: Specific Bazel version
                // Add other necessary packages here
              ];
            };
          });
    }
    ```

3.  **`shell.nix`**: This file acts as a compatibility layer for tools that expect a traditional Nix shell.
    ```nix
    (import
      (
        let lock = builtins.fromJSON (builtins.readFile ./flake.lock); in
        fetchTarball {
          url = "https://github.com/edolstra/flake-compat/archive/${lock.nodes.flake-compat.locked.rev}.tar.gz";
          sha256 = lock.nodes.flake-compat.locked.narHash;
        }
      )
      { src = ./.; }
    ).shellNix
    ```

[nps]: https://search.nixos.org/packages

### Workspace Setup (Bazel `WORKSPACE` file)

Add the following to your Bazel `WORKSPACE` file (typically at the root of your repository). This configures Bazel to use the Nix setup.

```
load("@bazel_tools//tools/build_defs/repo:git.bzl", "git_repository")
load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_archive")


http_archive(
    name = "rules_cc",
    integrity = "sha256-IDeHW5pEVtzkp50RKorohbvEqtlo5lh9ym5k86CQDN8=",
    # Ensure this is the version of rules_cc you intend to use
    urls = [
        "https://github.com/bazelbuild/rules_cc/releases/download/0.0.9/rules_cc-0.0.9.tar.gz",
    ],
    strip_prefix = "rules_cc-0.0.9",
)
http_archive(
    name = "io_tweag_rules_nixpkgs",
    # Ensure this commit hash points to a stable/desired version of rules_nixpkgs
    strip_prefix = "rules_nixpkgs-126e9f66b833337be2c35103ce46ab66b4e44799",
    urls = ["https://github.com/tweag/rules_nixpkgs/archive/126e9f66b833337be2c35103ce46ab66b4e44799.tar.gz"],
    sha256 = "480df4a7777a5e3ee7a755ab38d18ecb3ddb7b2e2435f24ad2037c1b084faa65",
)
load("@io_tweag_rules_nixpkgs//nixpkgs:repositories.bzl", "rules_nixpkgs_dependencies")
rules_nixpkgs_dependencies()
load("@io_tweag_rules_nixpkgs//nixpkgs:nixpkgs.bzl", "nixpkgs_local_repository")
nixpkgs_local_repository(
    name = "nixpkgs",
    nix_flake_lock_file = "//:flake.lock",
    nix_file_deps = ["//:flake.lock"],
)
# Configure the C++ toolchain
load("@io_tweag_rules_nixpkgs//nixpkgs:nixpkgs.bzl", "nixpkgs_cc_configure")
nixpkgs_cc_configure(
    name = "nixpkgs_config_cc",
    repository = "@nixpkgs",
    attribute_path = "clang_13",
)
load("@rules_cc//cc:repositories.bzl", "rules_cc_dependencies", "rules_cc_toolchains")
rules_cc_dependencies()
rules_cc_toolchains()

git_repository(
    name = "bazel_local_nix",
    remote = "https://github.com/filmil/bazel_local_nix",
    # Ensure this commit hash points to a stable/desired version of bazel_local_nix
    commit = "1658ed1563b6862abac349b407234ceee0a57ae0",
)

load("@bazel_local_nix//:repositories.bzl", "bazel_local_nix_dependencies")
bazel_local_nix_dependencies()
```

### Configure Bazel via `.bazelrc`

Add the following lines to your `.bazelrc` file (create one in your repository root if it doesn't exist). This defines a `nix` configuration for Bazel.

```
common:nix --host_platform=@rules_nixpkgs_core//platforms:host
common:nix --incompatible_enable_cc_toolchain_resolution
```

These settings ensure that when you use the `--config=nix` flag:
1.  The host platform is correctly set for the Nix tooling provided by `rules_nixpkgs`. This is crucial for Nix-based toolchains to function correctly.
2.  Bazel's modern C++ toolchain resolution is enabled, which uses the `--host_platform` for selecting toolchains, rather than the older `--crosstool_top` mechanism.

### Install the Bazel Wrapper Script

This project provides a wrapper script that Bazel uses to enter the ephemeral Nix environment. Install it by running the following Bazel command:

```
bazel --max_idle_secs=1 run @bazel_local_nix//:install
```

This command runs the `install` target from the `@bazel_local_nix//:install` package, which places the wrapper script (typically at `//tools/bazel`) in your workspace.

**Bootstrapping Note:** If you're setting up ephemeral Nix for an entire project for the first time, you might need to temporarily disable any early toolchain checks in your existing Bazel configuration. Such checks can be placed under an environment-variable-protected flag in a file like `//tools/bazel_local_nix.config.sh`. This file can then be used to bootstrap the installation for other users checking out the source code.

### Build with Nix Configuration

Once the setup is complete, build your project using the `nix` configuration:

```
bazel build --config=nix //...
```

If the build succeeds, the ephemeral Nix environment is working correctly!

Subsequent users of the repository, and your CI system, will only need to remember to include `--config=nix` in their Bazel commands. Alternatively, they can add `build --config=nix` to their user-specific `.bazelrc` file (e.g., `~/.bazelrc` or `user.bazelrc` in the project root) to apply it automatically.

## Maintenance

### Updating Nix Dependencies (`flake.lock`)

To update your Nix dependencies (which are pinned in `flake.lock`), you'll currently need to do this outside of Bazel. (A future enhancement could be a Bazel rule to manage this.)

In the directory containing your `flake.nix` and `flake.lock` files, run:

```
nix-portable nix flake update
```

## Contributing

We welcome contributions from the community! Whether it's reporting a bug, asking a question, or proposing an improvement, your input is valuable.

### Reporting Issues

If you encounter a bug or unexpected behavior, please [file an issue][ff] on our GitHub repository.
To help us diagnose the problem effectively, please include:
*   A clear description of the issue.
*   Steps to reproduce the behavior.
*   A minimal reproduction case, if possible. This helps isolate the problem and speeds up the resolution.
*   Information about your environment (e.g., operating system, Bazel version, Nix version if relevant).

### Asking Questions

For questions about using this project, you can also use GitHub Issues. Please try to be specific in your question and provide context. You might want to tag your issue with a "question" label if the repository uses them.

### Proposing Changes

Pull requests are welcome for bug fixes, documentation improvements, or new features.
For significant changes or new features, it's often a good idea to open an issue first to discuss your proposal. This allows for feedback and ensures that your contribution aligns with the project's goals.

When submitting a pull request, please:
*   Clearly describe the changes you've made.
*   Explain the motivation for your changes.
*   Ensure your code adheres to any existing style guidelines.
*   Add or update tests if applicable.

## Troubleshooting

### The built binaries can not find shared libraries

The shared libraries paths will be something like `/nix/store/...`.
This means that a binary built inside a HER build might not work at all outside of the bazel repo.
This is not very useful. What to do?

Fortunately, the nice people at tweag.io have got you covered.
Please see their project `clodl` at: https://github.com/tweag/clodl.
This project allows you to build an archive with a transitive closure of the libraries you need.
Check the licensing, though.

I am also not quite sure what you would need to do to make truly portable packaging.
I suspect some `readelf` tricks would be necessary, but I haven't done the legwork.
It is always hard to provide a self-contained binary when shared libraries are involved.

### Other

If you encounter other issues or have questions, please see the [Contributing](#contributing) section for information on how to report them or ask for help.

[ff]: https://github.com/filmil/bazel_local_nix/issues

