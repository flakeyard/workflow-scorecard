#!/usr/bin/env bash
# Static tests of the workflows of this repository and unit tests of its
# scripts. The suites in tests/unit/workflows have one file per workflow and
# read workflows with mikefarah yq v4, tests/unit/scripts has one file per
# script of scripts/, and tests/unit/lib tests the helpers in tests/lib.
# Usage: tests/run.sh
# shellcheck source-path=SCRIPTDIR
set -uo pipefail
shopt -s globstar

root=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
# shellcheck source=lib/case.sh
source "$root/tests/lib/case.sh"
# shellcheck source=lib/workflow.sh
source "$root/tests/lib/workflow.sh"
# shellcheck source=lib/scorecard.sh
source "$root/tests/lib/scorecard.sh"

for suite in "$root"/tests/unit/**/*.sh; do
  # shellcheck source=/dev/null
  source "$suite"
done

echo "passed: $passed, failed: $failed"
((failed == 0))
