#!/usr/bin/env bash
# Static tests of the workflows of this repository and unit tests of its
# scripts, with the harness of internal/testing of the shell library. The
# suites in tests/unit/workflows have one file per workflow and read workflows
# with mikefarah yq v4, tests/unit/scripts has one file per script of
# scripts/, and tests/unit/lib tests the helpers in tests/lib.
# Usage: tests/run.sh
# shellcheck source-path=SCRIPTDIR
set -uo pipefail
shopt -s globstar

root=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
readonly LIBRARY_URL=https://github.com/flakeyard/action-shell-lib
# The pin of the library; the commit is the first group.
readonly LIBRARY_PIN_RE='uses: flakeyard/action-shell-lib@([0-9a-f]{40})'

# load_library FILE: unless SHELL_LIB is set, as by the unit check of the
# flake, export it as the library at the commit that FILE pins, fetched once
# into the cache. Each repository keeps this loader, since it cannot come from
# the library that it loads (FY-0035).
load_library() {
  local file=$1 commit
  [[ -z ${SHELL_LIB-} ]] || return 0
  [[ $(<"$file") =~ $LIBRARY_PIN_RE ]] || { echo "$file pins no action-shell-lib" >&2 && exit 2; }
  commit=${BASH_REMATCH[1]}
  export SHELL_LIB=${XDG_CACHE_HOME:-$HOME/.cache}/flakeyard/action-shell-lib/$commit
  # HEAD is set once the checkout is complete, so a failed fetch is repeated.
  git -C "$SHELL_LIB" rev-parse -q --verify HEAD &>/dev/null || { git init -q "$SHELL_LIB" \
    && git -C "$SHELL_LIB" fetch -q --depth 1 "$LIBRARY_URL" "$commit" \
    && git -C "$SHELL_LIB" checkout -qf FETCH_HEAD; } || exit 2
}

load_library "$root/.github/workflows/test.yaml"
# The harness of the library; not its public API, used only by tests.
testing=$SHELL_LIB/internal/testing
# shellcheck source=/dev/null
source "$testing/case.sh"
# shellcheck source=/dev/null
source "$testing/checks.sh"
# shellcheck source=/dev/null
source "$testing/yaml.sh"
# shellcheck source=/dev/null
source "$testing/consumer/action.sh"
# The scripts and the YAML files are paths in the repository.
# shellcheck disable=SC2034 # read by internal/testing
code_root=$root
# shellcheck source=lib/workflow.sh
source "$root/tests/lib/workflow.sh"
# shellcheck source=lib/scorecard.sh
source "$root/tests/lib/scorecard.sh"

for suite in "$root"/tests/unit/**/*.sh; do
  # shellcheck source=/dev/null
  source "$suite"
done

conclude
