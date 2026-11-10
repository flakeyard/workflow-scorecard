# shellcheck shell=bash
# Static tests of the workflows of this repository, on yaml.sh of the harness
# of the shell library. Source this file after it; it expects root, the
# repository's directory.
# shellcheck disable=SC2016 # jq expressions, not expansions.
# shellcheck disable=SC2034 # current is the test that report and finish count.

: "${root:?}"

# Helpers of the expressions of workflow_check.
readonly WORKFLOW_DEFS='
  def condition: (.if // "") | gsub("\\s+"; " ");
'

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

# load_workflow FILE: print the workflow FILE of .github/workflows as JSON.
load_workflow() {
  local file=$1
  load_yaml ".github/workflows/$file"
}

# workflow_check WORKFLOW NAME FILTER: FILTER, a jq expression over WORKFLOW,
# the JSON of load_workflow, with the helpers above, is true.
workflow_check() {
  local workflow=$1 name=$2 filter=$3
  yaml_check "$workflow" "$name" "$WORKFLOW_DEFS $filter"
}
