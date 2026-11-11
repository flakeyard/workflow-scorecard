# shellcheck shell=bash
# Static tests of the workflows of this repository, beside workflow.sh of the
# harness of the shell library. Source this file after it; it expects root,
# the repository's directory.
# shellcheck disable=SC2034 # current is the test that report and finish count.

: "${root:?}"

# require_workflow FILE: true when .github/workflows/FILE exists; otherwise
# fails a test of FILE.
require_workflow() {
  local file=$1
  [[ -f $root/.github/workflows/$file ]] && return 0
  setup
  current="$file: the workflow exists"
  report "no .github/workflows/$file"
  finish
  return 1
}
