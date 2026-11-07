#!/bin/sh
#
# The installer of the Feature nectar: installs into /usr/local/bin the nectar of the release
# VERSION names, verified against the checksums SHA256SUMS carries. The workflow
# take-nectar-release.yml writes both files from a release of hivevm/nectar whose attestations it
# verified; without them the installation fails.

set -eu
here="$(cd "$(dirname "$0")" && pwd)"
if [ ! -f "$here/SHA256SUMS" ] || [ ! -f "$here/VERSION" ]; then
  echo "nectar Feature: this Feature names no release of nectar yet" >&2
  exit 1
fi
exec sh "$here/install-nectar.sh" "$here/SHA256SUMS" "$here/VERSION" /usr/local/bin
