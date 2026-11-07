# nuc

Installs [`nuc`](https://github.com/hivevm/nuc-tools), the mechanics of the
[NUC](https://github.com/hivevm/nuc) template, into `/usr/local/bin`.

```json
"features": {
  "ghcr.io/hivevm/features/nuc:0": {}
}
```

Each version of the Feature installs the `nuc` of the same version. The binary is downloaded from
the GitHub release of `hivevm/nuc-tools` and checked against the checksums this version carries,
which were written only after the release's build-provenance attestations were verified. A binary
whose checksum differs fails the installation.

Platforms: Linux on x64 and arm64.
