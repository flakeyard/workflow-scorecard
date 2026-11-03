# shellcheck shell=bash
# Static tests of a workflow: jq expressions over the workflow, read as JSON
# with mikefarah yq v4, which GitHub-hosted runners have. Source this file
# after case.sh; it expects root, the repository's directory.
# shellcheck disable=SC2016 # jq expressions, not expansions.

: "${root:?}"

# Helpers of the expressions of workflow_check.
readonly WORKFLOW_DEFS='
  def condition: (.if // "") | gsub("\\s+"; " ");
'

# have_yq: mikefarah yq v4 is installed.
have_yq() {
  command -v yq >/dev/null && [[ $(yq --version 2>&1) == *mikefarah* ]]
}

# require_yq FILE: true when yq is installed; otherwise fails a test of FILE.
require_yq() {
  local file=$1
  have_yq && return 0
  start "$file: yq is installed"
  report "the static tests of the workflows need mikefarah yq v4; run them with: nix shell nixpkgs#yq-go -c tests/run.sh"
  return 1
}

# require_workflow FILE: true when .github/workflows/FILE exists; otherwise
# fails a test of FILE.
require_workflow() {
  local file=$1
  [[ -f $root/.github/workflows/$file ]] && return 0
  start "$file: the workflow exists"
  report "no .github/workflows/$file"
  return 1
}

# yaml_json PATH: print the YAML file PATH as JSON.
yaml_json() {
  local path=$1
  yq -o=json . "$path"
}

# load_workflow FILE: print the workflow FILE of .github/workflows as JSON.
load_workflow() {
  local file=$1
  yaml_json "$root/.github/workflows/$file"
}

# workflow_check WORKFLOW NAME FILTER: FILTER, a jq expression over WORKFLOW,
# the JSON of load_workflow, is true.
workflow_check() {
  local workflow=$1 name=$2 filter=$3
  start "$name"
  jq -e "$WORKFLOW_DEFS $filter" <<<"$workflow" >/dev/null \
    || report "not true: $filter"
  finish
}
