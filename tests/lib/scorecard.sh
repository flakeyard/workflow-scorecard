# shellcheck shell=bash
# The rules of a Scorecard workflow, in scorecard.jq, applied to a workflow
# file. Source this file after yaml.sh of the harness; it expects root, the
# repository's directory.

: "${root:?}"
readonly SCORECARD_RULES=${root}/tests/lib/scorecard.jq

# scorecard_violations PATH: print the violations of the rules by the workflow
# at PATH, in the repository, one per line; fails when the file cannot be
# read.
scorecard_violations() {
  local path=$1 json
  json=$(load_yaml "${path}") || return
  jq -r -f "${SCORECARD_RULES}" <<<"${json}"
}

# scorecard_broken_rules PATH: print the rules the workflow at PATH, in the
# repository, breaks, sorted and separated by spaces; fails when the file
# cannot be read.
scorecard_broken_rules() {
  local path=$1 rules
  rules=$(scorecard_violations "${path}") || return
  rules=$(cut -d: -f1 <<<"${rules}") || return
  rules=$(sort -u <<<"${rules}") || return
  printf '%s\n' "${rules//$'\n'/ }"
}
