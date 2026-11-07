#!/bin/bash
# The test of the Feature nectar, run by 'devcontainer features test' in each base image it serves.
set -e
source dev-container-features-test-lib
check "nectar is on the PATH" bash -c "command -v nectar"
check "nectar runs" bash -c "nectar --version | grep -Eq '^nectar [0-9]+\.[0-9]+\.[0-9]+$'"
check "nectar builds a project to a PDF" bash -c '
  dir="$(mktemp -d)" && cd "$dir" &&
  printf "[[document]]\nsource = \"manual.md\"\n" > nectar.toml &&
  printf "# Manual\n\nHello.\n" > manual.md &&
  nectar --offline build -o out && head -c 4 out/print/manual.pdf | grep -q "%PDF"'
reportResults
