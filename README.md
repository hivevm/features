# hivevm/features

Dev Container Features of the hivevm tools, published under one namespace,
`ghcr.io/hivevm/features`.

| Feature | Installs | Reference |
|---------|----------|-----------|
| [`nuc`](src/nuc/) | [`nuc`](https://github.com/hivevm/nuc-tools), the mechanics of the [NUC](https://github.com/hivevm/nuc) template | `ghcr.io/hivevm/features/nuc:0` |

```json
"features": {
  "ghcr.io/hivevm/features/nuc:0": {}
}
```

## How a Feature takes a tool's release

A tool's repository publishes its binaries, their `SHA256SUMS`, and a build-provenance
attestation per binary; it never writes to this repository. This repository pulls each release:

1. `take-nuc-release.yml` runs weekly, or by hand with a version. `scripts/take-nuc-release.sh`
   downloads the release, checks every binary against `SHA256SUMS`, verifies each attestation
   against the release workflow of the tool's repository, and only then writes the checksums and
   the version into the Feature.
2. It opens a pull request. A human merges it.
3. `release.yml` tests the Features and publishes each at the version its
   `devcontainer-feature.json` names.

A Feature installs the binary of the version it names and checks it against the checksums it
carries, so a binary replaced in the tool's release fails the installation. A Feature that names
no release yet is neither tested nor published.

## Layout

```text
src/<id>/               # one Feature: devcontainer-feature.json, install.sh, its README
test/<id>/test.sh       # the test 'devcontainer features test' runs in each base image
scripts/                # what the workflows run, such as take-nuc-release.sh
.github/workflows/      # test.yml, release.yml, take-nuc-release.yml
```

`src/nuc/install-nuc.sh` is a copy of
[`release/install-nuc.sh`](https://github.com/hivevm/nuc-tools/blob/main/release/install-nuc.sh)
of `hivevm/nuc-tools`, which tests it there; take a new copy when it changes.

## Repository settings

- Actions may create pull requests (*Settings → Actions → General → Workflow permissions*), for
  `take-nuc-release.yml`.
- After the first publication, set each package `features/<id>` on ghcr.io to public; ghcr.io
  makes a new package private.
- A pull request opened by the workflow token starts no workflow, so its tests run once a human
  closes and reopens it.

## License

Released under the MIT License. See [`LICENSE`](LICENSE).
