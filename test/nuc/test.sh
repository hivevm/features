#!/bin/bash
# The test of the Feature nuc, run by 'devcontainer features test' in each base image.
set -e
source dev-container-features-test-lib
check "nuc is on the PATH" bash -c "command -v nuc"
check "nuc runs" bash -c "nuc --version | grep -Eq '^nuc [0-9]+\.[0-9]+\.[0-9]+$'"
reportResults
