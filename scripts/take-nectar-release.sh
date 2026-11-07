#!/usr/bin/env bash
#
# Takes a release of hivevm/nectar into the Feature nectar: downloads its SHA256SUMS and every
# archive the file names, checks each archive against its checksum and verifies its
# build-provenance attestation, signed by the release workflow of hivevm/nectar, and only then
# writes src/nectar/SHA256SUMS, src/nectar/VERSION, and the version of
# src/nectar/devcontainer-feature.json.
#
# What it relies on is the interface hivevm/nectar keeps until a major release
# (ADR-draft-release-interface there): the tag nectar-vX.Y.Z, the assets
# nectar-X.Y.Z-<target>.tar.gz or .zip under releases/download/nectar-vX.Y.Z/, SHA256SUMS with one
# line '<sha256>  <asset>' per archive, and an attestation per archive.
#
# Usage: scripts/take-nectar-release.sh [X.Y.Z]   (the latest release when none is given)
# Needs gh, authenticated through GH_TOKEN. Prints the version taken, or nothing when the Feature
# already names it. Exit code 0 on success, 1 otherwise.

set -euo pipefail

REPO=hivevm/nectar
SIGNER="$REPO/.github/workflows/nectar-release.yml"
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
feature="$ROOT/src/nectar"

fail() { echo "take-nectar-release: $1" >&2; exit 1; }

version="${1:-}"
if [[ -z "$version" ]]; then
  # The repository may hold other releases too; the newest tagged nectar-v* is Nectar's.
  tag="$(gh release list --repo "$REPO" --exclude-drafts --exclude-pre-releases --json tagName \
    --jq '[.[] | select(.tagName | startswith("nectar-v"))][0].tagName // empty')" \
    || fail "no release of $REPO could be read"
  [[ -n "$tag" ]] || fail "$REPO has no release tagged nectar-v*"
  version="${tag#nectar-v}"
fi
[[ "$version" =~ ^(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)$ ]] \
  || fail "'$version' is no version X.Y.Z"
current="$(tr -d '[:space:]' < "$feature/VERSION" 2>/dev/null || true)"
[[ "$current" == "$version" ]] && exit 0

work="$(mktemp -d)"
trap 'rm -rf "$work"' EXIT
gh release download "nectar-v$version" --repo "$REPO" --dir "$work" \
  --pattern 'SHA256SUMS' --pattern "nectar-$version-*" \
  || fail "the release nectar-v$version of $REPO could not be downloaded"
[[ -s "$work/SHA256SUMS" ]] || fail "the release nectar-v$version carries no SHA256SUMS"

# Every line is '<sha256>  nectar-X.Y.Z-<target>.tar.gz' or '.zip', of this version, and every
# archive it names is in the release.
escaped="${version//./\\.}"
while read -r sum asset rest; do
  [[ "$sum" =~ ^[0-9a-f]{64}$ && "$asset" =~ ^nectar-${escaped}-[a-z0-9_]+-[a-z0-9_-]+\.(tar\.gz|zip)$ && -z "$rest" ]] \
    || fail "SHA256SUMS holds a line not in the form '<sha256>  nectar-$version-<target>.tar.gz': $sum $asset $rest"
  [[ -f "$work/$asset" ]] || fail "SHA256SUMS names $asset, which the release lacks"
done < "$work/SHA256SUMS"

(cd "$work" && sha256sum --check --strict --quiet SHA256SUMS) \
  || fail "an archive of nectar-v$version differs from its checksum"
while read -r _ asset; do
  gh attestation verify "$work/$asset" --repo "$REPO" --signer-workflow "$SIGNER" >/dev/null \
    || fail "the attestation of $asset in nectar-v$version does not verify"
done < "$work/SHA256SUMS"

cp "$work/SHA256SUMS" "$feature/SHA256SUMS"
printf '%s\n' "$version" > "$feature/VERSION"
sed -i -E "s/^(  \"version\": )\"[^\"]*\",$/\1\"$version\",/" "$feature/devcontainer-feature.json"
grep -q "^  \"version\": \"$version\",$" "$feature/devcontainer-feature.json" \
  || fail "the version of devcontainer-feature.json could not be set"
echo "$version"
