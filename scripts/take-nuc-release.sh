#!/usr/bin/env bash
#
# Takes a release of hivevm/nuc-tools into the Feature nuc: downloads its SHA256SUMS and every
# binary the file names, checks each binary against its checksum and verifies its build-provenance
# attestation, signed by the release workflow of hivevm/nuc-tools, and only then writes
# src/nuc/SHA256SUMS, src/nuc/VERSION, and the version of src/nuc/devcontainer-feature.json.
#
# What it relies on is the interface hivevm/nuc-tools keeps until a major release: the tag vX.Y.Z,
# the assets nuc-<target> under releases/download/vX.Y.Z/, SHA256SUMS with one line
# '<sha256>  <asset>' per binary, and an attestation per binary.
#
# Usage: scripts/take-nuc-release.sh [X.Y.Z]   (the latest release when none is given)
# Needs gh, authenticated through GH_TOKEN. Prints the version taken, or nothing when the Feature
# already names it. Exit code 0 on success, 1 otherwise.

set -euo pipefail

REPO=hivevm/nuc-tools
SIGNER="$REPO/.github/workflows/release.yml"
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
feature="$ROOT/src/nuc"

fail() { echo "take-nuc-release: $1" >&2; exit 1; }

version="${1:-}"
if [[ -z "$version" ]]; then
  tag="$(gh release view --repo "$REPO" --json tagName --jq .tagName)" \
    || fail "no release of $REPO could be read"
  version="${tag#v}"
fi
[[ "$version" =~ ^(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)$ ]] \
  || fail "'$version' is no version X.Y.Z"
current="$(tr -d '[:space:]' < "$feature/VERSION" 2>/dev/null || true)"
[[ "$current" == "$version" ]] && exit 0

work="$(mktemp -d)"
trap 'rm -rf "$work"' EXIT
gh release download "v$version" --repo "$REPO" --dir "$work" --pattern 'SHA256SUMS' --pattern 'nuc-*' \
  || fail "the release v$version of $REPO could not be downloaded"
[[ -s "$work/SHA256SUMS" ]] || fail "the release v$version carries no SHA256SUMS"

# Every line is '<sha256>  nuc-<target>', and every binary it names is in the release.
while read -r sum asset rest; do
  [[ "$sum" =~ ^[0-9a-f]{64}$ && "$asset" =~ ^nuc-[a-z0-9_]+-[a-z0-9_-]+(\.exe)?$ && -z "$rest" ]] \
    || fail "SHA256SUMS holds a line not in the form '<sha256>  nuc-<target>': $sum $asset $rest"
  [[ -f "$work/$asset" ]] || fail "SHA256SUMS names $asset, which the release lacks"
done < "$work/SHA256SUMS"

(cd "$work" && sha256sum --check --strict --quiet SHA256SUMS) \
  || fail "a binary of v$version differs from its checksum"
while read -r _ asset; do
  gh attestation verify "$work/$asset" --repo "$REPO" --signer-workflow "$SIGNER" >/dev/null \
    || fail "the attestation of $asset in v$version does not verify"
done < "$work/SHA256SUMS"

cp "$work/SHA256SUMS" "$feature/SHA256SUMS"
printf '%s\n' "$version" > "$feature/VERSION"
sed -i -E "s/^(  \"version\": )\"[^\"]*\",$/\1\"$version\",/" "$feature/devcontainer-feature.json"
grep -q "^  \"version\": \"$version\",$" "$feature/devcontainer-feature.json" \
  || fail "the version of devcontainer-feature.json could not be set"
echo "$version"
