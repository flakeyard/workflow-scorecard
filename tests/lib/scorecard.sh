# shellcheck shell=bash
# The rules of a Scorecard workflow, in scorecard.jq, applied to a workflow
# file. Source this file after workflow.sh; it expects root, the repository's
# directory.

: "${root:?}"
readonly SCORECARD_RULES=$root/tests/lib/scorecard.jq

# scorecard_violations PATH: print the violations of the rules by the workflow
# at PATH, one per line; fails when the file cannot be read.
scorecard_violations() {
  local path=$1
  yaml_json "$path" | jq -r -f "$SCORECARD_RULES"
}

# scorecard_broken_rules PATH: print the rules the workflow at PATH breaks,
# sorted and separated by spaces.
scorecard_broken_rules() {
  local path=$1
  scorecard_violations "$path" | cut -d: -f1 | sort -u | paste -sd' ' -
}
