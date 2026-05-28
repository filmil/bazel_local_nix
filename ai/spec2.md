<!-- SPDX-License-Identifier: Apache-2.0 -->

# rules_nix — Technical Requirements Specification (Nix variant)

> This document is `spec.md` adapted to target **Nix** instead of GNU Guix.
> It keeps the same structure and intent; sections that differ materially from
> the Guix specification are called out. Where the Guix spec encodes a
> Guile/Guix-specific behaviour, this variant either drops it (it does not
> apply to Nix) or replaces it with the Nix equivalent.

## 1. Purpose

`rules_nix` is a set of Bazel rules that make Nix packages available inside a
Bazel workspace **without requiring a host-level Nix installation**. It
bootstraps an ephemeral Nix from the official release, runs an unprivileged
Nix inside a user namespace, and exposes the resulting self-contained package
bundles as ordinary Bazel artifacts.

This is the authoritative requirements specification for the Nix variant. It
is intended to be read alongside `//ai/requirements.md`, `//ai/tasks`,
`//ai/datasheet.md`, and the Guix-targeted `//ai/spec.md`.

## 2. Scope

In scope:

- A repository rule that fetches and unpacks the Nix binary release.
- A wrapper that runs `nix` subcommands against an ephemeral, persistent store
  under `bwrap`, configured to use the public binary cache.
- Build rules that turn a Nix installable into a Bazel-tracked archive and that
  unpack such an archive into a usable directory tree.
- Generated reference documentation, an integration-test module, and the
  CI/release machinery to publish the module to Bazel registries.

Out of scope (current revision):

- Running on non-Linux/non-`x86_64` hosts.
- Multi-user (root daemon) Nix installs; this variant uses single-user,
  unprivileged Nix (see §6.2).
- Bazel toolchain registration via `toolchain()`/`register_toolchains`
  (the `nix_toolchain` rule only extracts a bundle; see §6.4).

## 3. Definitions

- **Bundle** — a relocatable, self-contained artifact produced by
  `nix bundle` (e.g. via the default `toarx` bundler), analogous to a Guix
  `guix pack -RR` archive.
- **Store** — the `/nix/store` content-addressed directory.
- **Bootstrap repo** — the external repository `@nix_bootstrap` materialised by
  the `nix_bootstrap` repository rule.
- **Substituter / binary cache** — a server (e.g. `https://cache.nixos.org`)
  that serves pre-built store paths.
- **Installable** — a Nix attribute/flake reference identifying what to build,
  e.g. `nixpkgs#hello`.
- **`CACHE_BASE`** — the persistent directory holding the writable Nix store
  and database across builds.

## 4. System Context and External Dependencies

- **REQ-ENV-1** The host SHALL provide `bwrap` (bubblewrap) on `PATH` and
  permit unprivileged user namespaces.
- **REQ-ENV-2** The host SHALL provide `bash`, `tar`, `xz`, `cp`, `flock`,
  and `coreutils`-level utilities.
- **REQ-ENV-3** Network egress SHALL be available to the Nix release host
  (`https://releases.nixos.org`) and to the configured binary cache
  (`https://cache.nixos.org`).
- **REQ-ENV-4** The target platform is `x86_64-linux`. Other platforms are
  unsupported in this revision.
- **REQ-ENV-5** Bazel SHALL be invoked with bzlmod enabled; the pinned Bazel
  version is recorded in `.bazelversion` (currently `9.1.0`).

## 5. Module and Toolchain Requirements

- **REQ-MOD-1** The module SHALL be named `rules_nix` and declare a SemVer
  `version` in `MODULE.bazel`.
- **REQ-MOD-2** The module SHALL depend (via `bazel_dep`) on, at minimum:
  `bazel_skylib`, `bazel_lib`, `rules_go`, and `gazelle`. `stardoc`
  and `bazel_skylib_gazelle_plugin` MAY be declared as `dev_dependency`.
- **REQ-MOD-3** The Go SDK and Go dependencies SHALL be derived from
  `//:go.mod` via the `rules_go`/`gazelle` module extensions.
- **REQ-MOD-4** `.bazelrc` SHALL configure the registries used to resolve
  modules (personal registry first, then the Bazel Central Registry) and SHALL
  set `test --test_output=errors`.
- **REQ-MOD-5** Per project policy (`GEMINI.md`), `.bazelrc` SHOULD load an
  optional `user.bazelrc`, and `bazel-*` SHALL be git-ignored.

## 6. Functional Requirements

### 6.1 Bootstrap repository rule (`nix_bootstrap`)

- **FR-BOOT-1** `nix_bootstrap` SHALL be a repository rule, instantiable from
  `MODULE.bazel` via `use_repo_rule`.
- **FR-BOOT-2** It SHALL download a pinned Nix binary release
  (`nix-<version>-x86_64-linux.tar.xz` from `releases.nixos.org`) by URL with a
  pinned `sha256`, and SHALL fail closed on checksum mismatch.
- **FR-BOOT-3** It SHALL unpack the archive, yielding the relocatable Nix
  toolchain and the seed `store/` contents.
- **FR-BOOT-4** It SHALL materialise the runtime wrapper `nix_wrapper.sh` from
  the source template `//:nix_wrapper.sh.tpl` via `repository_ctx.template`
  (the wrapper SHALL NOT be embedded as an inline string literal).
- **FR-BOOT-5** It SHALL generate a `BUILD` file exposing:
  - `nix_wrapper.sh` via `exports_files`, and
  - a public `filegroup` named `nix_binaries` globbing the unpacked tree.

### 6.2 Runtime wrapper (`nix_wrapper.sh.tpl`)

The wrapper runs an arbitrary `nix` subcommand (`"$@"`) inside `bwrap`.

- **FR-WRAP-1** It SHALL run Nix in **single-user, unprivileged** mode inside a
  `bwrap` user namespace; no host Nix, no root, and no system `nix-daemon` are
  required. (A user-owned `nix-daemon` MAY be started inside the namespace if a
  future revision needs build isolation, but is not required.)
- **FR-WRAP-2** It SHALL maintain a **persistent** Nix store and database
  across builds at `CACHE_BASE`, defaulting to
  `<output_user_root>/rules_nix_store` (derived from the real execroot) and
  overridable via the `RULES_NIX_CACHE` environment variable.
- **FR-WRAP-3** One-time store initialization (seeding the writable
  `CACHE_BASE` store from the shipped store) SHALL run only once, guarded by a
  `.store_ready` marker.
- **FR-WRAP-4** When copying Bazel-provided inputs into the writable store, the
  wrapper SHALL dereference symlinks (`-L`) so Bazel's per-file input symlinks
  resolve to real content. *(Unlike the Guix variant, Nix does not byte-compile
  Guile modules, so no `*.go` timestamp/`GUILE_AUTO_COMPILE` handling is
  required; the corresponding Guix requirements are intentionally dropped.)*
- **FR-WRAP-5** The wrapper SHALL configure Nix to use the public binary
  cache: `substituters = https://cache.nixos.org` and the trusted public key
  `cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY=`. The
  substituter list MAY be extended/overridden via configuration.
- **FR-WRAP-6** Environment/paths visible inside the sandbox (`HOME`,
  `XDG_CACHE_HOME`, `TMPDIR`, `NIX_CONF_DIR`, `NIX_STORE_DIR=/nix/store`,
  `NIX_STATE_DIR`) SHALL be **guest** paths corresponding to the `bwrap` bind
  mounts, not host paths.
- **FR-WRAP-7** The sandbox SHALL bind the host files required for name
  resolution and TLS: `/etc/resolv.conf`, `/etc/hosts`, `/etc/nsswitch.conf`,
  `/etc/services`, `/etc/ssl`, `/etc/passwd`, `/etc/group`. The CA bundle
  SHALL be made discoverable to Nix (e.g. via `NIX_SSL_CERT_FILE`).
- **FR-WRAP-8** Nix SHALL be invoked with the experimental features required
  for the chosen interface enabled (e.g. `--extra-experimental-features
  "nix-command flakes"`), and substitution SHALL be enabled (no
  `--option substitute false`).
- **FR-WRAP-9** Concurrent invocations sharing `CACHE_BASE` SHALL be serialized
  (via `flock`) to protect the single-user store/database.
- **FR-WRAP-10** The wrapper SHALL fail with a clear diagnostic (including the
  relevant Nix output) if the store cannot be initialized or a build fails.
- **FR-WRAP-11** Any guest `/nix/store/...` path printed by the subcommand on
  stdout SHALL be rewritten to its host location under `CACHE_BASE` so callers
  can read the artifact after the sandbox exits; non-path output SHALL pass
  through unchanged.
- **FR-WRAP-12** The wrapper SHALL clean up its per-run ephemeral scratch on
  exit and propagate the subcommand's exit status.
- **FR-WRAP-13** Discovery of the Nix binaries within the unpacked release
  SHALL be version-agnostic so that bumping the pinned release does not require
  editing the wrapper.

### 6.3 Package rule (`nix_package`)

- **FR-PKG-1** `nix_package(name, installable)` SHALL declare one output file
  `<name>.tar.gz` (a self-contained bundle).
- **FR-PKG-2** It SHALL invoke the wrapper to build a relocatable bundle for
  the installable (e.g. `nix bundle --bundler <relocatable-bundler>
  <installable>`), and copy the result to the declared output. The
  `installable` attribute SHALL default to a pinned `nixpkgs` reference so
  builds are reproducible.
- **FR-PKG-3** Its action SHALL carry execution requirements
  `requires-network`, `no-sandbox`, and `local`, reflecting that it reads/writes
  a persistent store, needs network for substitutes, and needs a stable real
  execroot from which to locate `CACHE_BASE`.
- **FR-PKG-4** It SHALL return a `DefaultInfo` whose files are the produced
  archive.

### 6.4 Toolchain rule (`nix_toolchain`)

- **FR-TC-1** `nix_toolchain(name, bundle)` SHALL accept a single bundle
  archive (typically a `nix_package` output) and extract it into a declared
  directory `<name>_extracted`.
- **FR-TC-2** The extracted directory SHALL be consumable by downstream rules
  (e.g. a `genrule` invoking `<dir>/bin/<tool>`).

### 6.5 Documentation generation

- **FR-DOC-1** Stardoc SHALL generate API reference for `nix_rules.bzl`
  (rules `nix_package`, `nix_toolchain`).
- **FR-DOC-2** A `write_source_files` target (`update_docs`) SHALL keep
  `nix_rules.md` in sync with the generated output, and SHALL be
  verifiable in CI.
- **FR-DOC-3** A Gazelle binary configured for Starlark SHALL be available to
  maintain `BUILD` files.

## 7. Build, Test, and Quality Requirements

- **REQ-BUILD-1** `bazel build //...` SHALL succeed for all non-network
  targets (the `bzl_library` targets, the Stardoc target, `update_docs`).
- **REQ-BUILD-2** An integration module under `//integration` SHALL consume
  `rules_nix` via `local_path_override` and exercise `nix_package` →
  `nix_toolchain` → a `genrule` that runs the bundled binary.
- **REQ-TEST-1** CI (`.github/workflows/test.yml`) SHALL run `bazel test
  //...` for the root module and for `//integration`, on push to `main`, on
  pull requests, and on a weekly schedule.
- **REQ-TEST-2** Network-dependent targets SHALL be tagged `requires-network`
  (and, where they use the persistent store, `no-sandbox`/`local`).

## 8. Repository Configuration Files (Dotfiles)

Every configuration dotfile in the repository is normative. Each SHALL exist
and satisfy the requirement below.

- **REQ-DOT-1 (`.bazelversion`)** SHALL pin an exact Bazel version `>= 9.0.1`
  (currently `9.1.0`). The root `//:.bazelversion` and
  `//integration/.bazelversion` SHALL be identical.
- **REQ-DOT-2 (`.bazelrc`)** SHALL declare the module registries in priority
  order (personal registry, then BCR), set `test --test_output=errors`, enable
  `build --announce_rc`, and SHOULD `try-import` an optional `user.bazelrc`.
- **REQ-DOT-3 (`.bazelignore`)** SHALL exclude the nested `integration`
  workspace from the root build.
- **REQ-DOT-4 (`.gitignore`)** SHALL ignore at least: `bazel-*`, the ephemeral
  Nix scratch (`result`, `result-*`), and transient build logs
  (`build_output.log`). *(Replaces the Guix `.guix-profile`/`.guix-gc-root`
  entries with the Nix `result*` symlinks.)*
- **REQ-DOT-5 (`.bcr/`)** SHALL contain `metadata.json`, `source.json`, and
  `presubmit.yml` as specified in §10.
- **REQ-DOT-6 (`.github/workflows/`)** SHALL contain the CI and release
  workflows as specified in §7 and §10.
- **REQ-DOT-7 (`.claude/settings.local.json`)** MAY provide a developer-local
  tool-permission allowlist and SHALL be non-normative for the build.

## 9. Development Workflow Requirements

Identical to the Guix variant; reproduced here for completeness.

- **REQ-WF-1** Commit titles SHALL follow Conventional Commits v1.0.0.
- **REQ-WF-2** Each commit message SHALL append the note `This commit has been
  created by an automated coding assistant, with human supervision.` followed
  by the exact prompt used, in full.
- **REQ-WF-3** Feature branches SHALL be created from `main` using the pattern
  `ai-dev-YYYYMMDD-NONCE-SHORT_TOPIC`, the `NONCE` produced by
  `scripts/generate_nonce.sh`.
- **REQ-WF-4** Integrating other branches SHALL prefer rebasing over merging;
  `git merge`/`rebase`/`cherry-pick` SHALL be run with `--no-edit`.
- **REQ-WF-5** Pull requests SHALL be created with `gh`, baselined on
  `origin/main`, summarizing all commits between `origin/main` and the branch
  tip, appending the automated-assistant note and the exact prompt, and a
  `Fixes: <URL>` line when closing an issue.
- **REQ-WF-6** Every newly created file SHALL carry an SPDX license annotation.
  New task/markdown files SHALL be tied into `//ai/tasks/BUILD.bazel`.
- **REQ-WF-7** Files under `//third_party` SHALL NOT be modified without
  explicit user permission.
- **REQ-WF-8** The CI workflow requirements of §7 SHALL gate merges to `main`.

## 10. Distribution and Release Requirements

- **REQ-REL-1** The module SHALL carry BCR publication metadata under `.bcr`
  (`metadata.json`, `source.json`, `presubmit.yml`).
- **REQ-REL-2** The BCR presubmit SHALL build and test `//...` on
  `ubuntu2004`, `macos`, and `windows`.
- **REQ-REL-3** A scheduled `tag-and-release` workflow SHALL test the module,
  bump the version tag, create a GitHub release with a source archive, and
  trigger publication.
- **REQ-REL-4** Publication workflows SHALL submit the module to both the
  project's personal registry and the Bazel Central Registry, using
  `bazel-contrib/publish-to-bcr`.

## 11. Constraints and Known Limitations

- **LIM-1** Nix's public binary cache (`cache.nixos.org`) retains substitutes
  for released `nixpkgs` revisions long-term. Consequently the **blocking**
  limitation of the Guix variant — a forced multi-hour source bootstrap because
  build-time substitutes were garbage-collected — is **not expected to apply**.
  With a pinned `nixpkgs` and the cache enabled, `nix_package` should download
  rather than build from source.
- **LIM-2** Reproducibility requires pinning the `nixpkgs` revision (flake lock
  or pinned tarball). An unpinned `nixpkgs#…` reference SHALL NOT be used in
  released rules, as it makes outputs non-deterministic.
- **LIM-3** Because `nix_package` runs `local` + `no-sandbox` and shares a
  persistent, mutable store, its actions are intentionally non-hermetic and
  serialized; remote execution is not supported.
- **LIM-4** The first build pays a one-time cost: store seeding plus substitute
  downloads. Subsequent builds reuse `CACHE_BASE`.
- **LIM-5** `nix bundle` relocatability depends on the chosen bundler;
  unprivileged execution of the produced bundle on the target may rely on user
  namespaces or a fallback (e.g. proot), as with Guix `-RR` packs.

## 12. Future Work

- **FUT-1** Support flake-pinned `nixpkgs` inputs as first-class rule
  attributes with lockfile integration.
- **FUT-2** Make `nix_toolchain` register a real Bazel toolchain rather than
  only extracting an archive.
- **FUT-3** Parameterize the bundler and output format on `nix_package`.
- **FUT-4** Evaluate `nix-portable` as an alternative bootstrap that removes
  the need for an explicit `bwrap` wrapper.
- **FUT-5** Add more example installables to `//integration`.

## 13. Traceability

| Area            | Primary artifact(s)                                  |
| :-------------- | :--------------------------------------------------- |
| Bootstrap rule  | `nix_bootstrap.bzl`                                  |
| Runtime wrapper | `nix_wrapper.sh.tpl`                                 |
| Build rules     | `nix_rules.bzl`                                      |
| Examples        | `BUILD`, `integration/BUILD`                         |
| Documentation   | `nix_rules.md` (generated), `README.md`              |
| Module/config   | `MODULE.bazel`, `.bazelrc`, `.bazelversion`, `go.mod`|
| CI / release    | `.github/workflows/*.yml`, `.bcr/*`                  |
