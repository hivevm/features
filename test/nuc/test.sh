#!/bin/sh
# The test of the Feature nuc, run by 'devcontainer features test' in each base image. POSIX sh
# without dev-container-features-test-lib, which needs bash: nuc serves Alpine, which has none.
set -e
failed=0
check() {
  label="$1"
  shift
  if "$@"; then
    echo "passed: $label"
  else
    echo "FAILED: $label"
    failed=1
  fi
}
check "nuc is on the PATH" command -v nuc
check "nuc runs" sh -c "nuc --version | grep -Eq '^nuc [0-9]+\.[0-9]+\.[0-9]+$'"
exit "$failed"
