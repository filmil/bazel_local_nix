# Hermetic, ephemeral and reproducible ("HER") Bazel builds [![Test status](https://github.com/filmil/bazel_local_nix/workflows/Test/badge.svg)](https://github.com/filmil/bazel_local_nix/workflows/Test/badge.svg)

This is an experiment in fully hermetic, but also self-installing [nix][nx]
based hermetic bazel build.

I call it a HER build.

[nx]: https://nixos.org

Sadly it only works on Linux today, since some essential parts are only work
under Linux. So if you are on Windows or Mac, ... or Fuchsia for that matter,
sorry.

## The problem with nix

If you are not ready to commit to using nix everywhere, you are stuck.

To elaborate a bit. Thanks to the work by tweag.io, it is possible to use nix
packages within bazel. The build rules at https://github.com/tweag/rules_nixpkgs 
allow bazel to bring in dependencies from [nixpkgs][nxp].

But, it requires having a `/nix/store` on
your machine. In turn, that means you need to have a pre-existing system-wide
nix installation.

If you do not, or you can not commit to doing that, then you can not use this.
Which is a bummer.

"Let's remove that problem!", I said one day, thinking it was going to be easy.
(It wasn't, but now it's done.)

[nxp]: https://github.com/NixOS/nixpkgs

## How I try to solve this

This repository goes one step further than what tweag.io has offered us: 
with the changes described here, `bazel` will install an **ephemeral**
nix store and pull in the appropriate dependencies from nixpkgs.

This means that
you **do not** need to install nix on your system to use the packages from nixpkgs.
`bazel` will do that for you. Moreover, the resulting nix installation will be
**ephemeral** and will only take effect within your bazel workspace.

Once the ephemeral nix is installed, you can use the tweag rules to bring in
the toolchains that are installed by nix.  Since both the bazel and the nix parts
of this setup are reproducible, and since the installation is ephemeral,
you also get a fully reproducible build as well.

And you don't need to stop at tweag-provided rules. You can depend on any binaries
you may need from the nix installation.

## So, what do I get from this exercise?

You get a source code repository that will self-install its development environment
when you attempt to build it for the first time.

This self-installed environment will not pollute your existing system at all. It does
not require `root` privileges to be installed, or to be run.

## Wait, doesn't `bazel` do this already?

Yes, *if* you only ever use dependencies that already build with bazel, or you know how
to bring them in line with bazel's expectations.

However, the real world is different: most dependencies you might want to use are *not*
aware of bazel, which means additional work to make them usable in a bazel build. Worse
yet, some dependencies may be outright hostile to operating within a bazel sandbox, which is its own can of worms.

Nix works around this wrinkle by allowing bazel to use a predictable dev environment
set up by nix.

This repo, in turn, removes the need for nix to be preinstalled on your machine for this
to work.

Taken together, it's a HER build.

## Does this work on remote builds?

I have not tried. I think that it could be made to work.

## References

See how this is used in the [integration test repo][itr].

[itr]: https://github.com/filmil/bazel_local_nix/tree/main/integration

Read [the article describing the approach][ta].

[ta]: https://hdlfactory.com/post/2024/04/20/nix-bazel-%EF%B8%8F/

I think it is important to note that the contribution of this repository is just in
using a handful of pre-existing tools in what seems to be a novel way, to a useful effect.

## Installation

Installation is done once per repository. Once the ephemeral nix changes have been committed, any new checkouts will use the nix installation automatically.

This means that whoever makes the changes first will need to know a tad bit more
than any later users of the repository.

**Note**: the setup is not production ready yet. While it should work, many sharp
corners may still exist. File a bug with a repro case if you want me to take a look
and perhaps help.  Proper documentation is also a bit wanting.

### Add the nix files

The HER configuration depends on a small number of nix files that we place in the
root directory of the repo. (You could also place them elsewhere by changing the obvious things such as references to `//:flake.lock` in the config files below.)

`flake.lock` contains the data used to reproduce the nix installation. It must 
be updated when you want to upgrade HER nix, which will be documented separately.
```
{
  "nodes": {
    "flake-compat": {
      "flake": false,
      "locked": {
        "lastModified": 1673956053,
        "narHash": "sha256-4gtG9iQuiKITOjNQQeQIpoIB6b16fm+504Ch3sNKLd8=",
        "owner": "edolstra",
        "repo": "flake-compat",
        "rev": "35bb57c0c8d8b62bbfd284272c928ceb64ddbde9",
        "type": "github"
      },
      "original": {
        "owner": "edolstra",
        "repo": "flake-compat",
        "type": "github"
      }
    },
    "flake-utils": {
        // ...
    }
  },
  "root": "root",
  "version": 7
}
```

`flake.nix`: creates the ephemeral environment that you want to use. Note that it is
based on a somewhat older version of `nixos`. This will be fixed soon enough. You want
to add to the `packages = [ ... ]` list any packages that you need in your build.
Use the [nixos package search][nps] to figure out the names of the packages.
```
{
  description = "C++ environment using Nix flakes";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-22.11";
    flake-compat = {
      url = "github:edolstra/flake-compat";
      flake = false;
    };
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { nixpkgs, flake-utils, ... }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs { inherit system; };

      in
      {
        devShells.default = with pkgs; mkShell {
          name = "flake-example-shell";
          packages = [ nix gcc gnumake bazel_6 ];
        };
      });
}
```

[nps]: https://search.nixos.org/packages

`shell.nix`:
```
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

### Workspace setup

Add the following to your WORKSPACE file:

```
load("@bazel_tools//tools/build_defs/repo:git.bzl", "git_repository")
load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_archive")

http_archive( 
    name = "rules_cc",
    sha256 = "4dccbfd22c0def164c8f47458bd50e0c7148f3d92002cdb459c2a96a68498241",
    urls = [
        "https://github.com/bazelbuild/rules_cc/releases/download/0.0.1/rules_cc-0.0.1.tar.gz",
    ],
)
http_archive(
    name = "io_tweag_rules_nixpkgs",
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
    commit = "1658ed1563b6862abac349b407234ceee0a57ae0",
)

load("@bazel_local_nix//:repositories.bzl", "bazel_local_nix_dependencies")
bazel_local_nix_dependencies()
```

### Modify your `.bazelrc` to add a nix-specific configuration

Add the following to your `.bazelrc`. If you do not have a file named `.bazelrc` in
the root of your repository, create it.

```
common:nix --host_platform=@rules_nixpkgs_core//platforms:host
common:nix --incompatible_enable_cc_toolchain_resolution
```

This does two things:

1. Sets the host platform to be compatible with the tweag nix tooling. This is essential to allow nix-based toolchains to be used in a build.
2. Turns on the new C++ toolchain resolution rules.  These instruct bazel to use `--host_platform` flags instead of `--crosstool_top`.  If you still use the latter, 
you should stop using the latter.

### Install `//tools/bazel`

Finally, install the script `//tools/bazel`, which bazel will use to wrap itself every time it is invoked:

```
bazel --max_idle_secs=1 run @bazel_local_nix//:install
```

You can now set up the rest of this project. Note that if you are setting
up ephemeral nix for the entire project, you may need to turn off any early
toolchain checks.  Place such checks under an env-protected flag, place
it under `//tools/bazel_local_nix.config.sh`. This will be used to bootstrap
installation for everyone else checking out the source.

### Compile

Once all of the above is done and done, the following should work:

```
bazel build --config=nix //...
```

If this works, you are done installing.  Any subsequent users will not need
to do anything special, except remember to use `--config=nix` in their build
commands -- or add to their `user.bazelrc` or some such.

Similarly, any continuous integration builds will need this flag. But this is usually a one-time setup, so I don't expect it to be a challenge.
