# nectar

Installs [`nectar`](https://github.com/hivevm/nectar), which turns Markdown into a website and a
PDF, into `/usr/local/bin`.

```json
"features": {
  "ghcr.io/hivevm/features/nectar:0": {}
}
```

Each version of the Feature installs the `nectar` of the same version. The archive is downloaded
from the GitHub release `nectar-vX.Y.Z` of `hivevm/nectar` and checked against the checksums this
version carries, which were written only after the release's build-provenance attestations were
verified. An archive whose checksum differs fails the installation.

Graphviz and PlantUML, which `nectar` runs for `dot` and `uml` blocks once a project configures
them, are not part of this Feature.

Platforms: Linux with glibc on x64 and arm64, such as the Debian and Ubuntu base images; not
Alpine, whose musl the release does not build for.
