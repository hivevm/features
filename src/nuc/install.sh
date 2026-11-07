#!/bin/sh
#
# The installer of the Feature nuc: installs into /usr/local/bin the nuc of the release VERSION
# names, verified against the checksums SHA256SUMS carries. The workflow take-nuc-release.yml
# writes both files from a release of hivevm/nuc-tools whose attestations it verified; without
# them the installation fails.

set -eu
here="$(cd "$(dirname "$0")" && pwd)"
if [ ! -f "$here/SHA256SUMS" ] || [ ! -f "$here/VERSION" ]; then
  echo "nuc Feature: this Feature names no release of nuc yet" >&2
  exit 1
fi
exec sh "$here/install-nuc.sh" "$here/SHA256SUMS" "$here/VERSION" /usr/local/bin
