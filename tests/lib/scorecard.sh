# shellcheck shell=bash
# The rules of a Scorecard workflow, in scorecard.jq, applied to a workflow
# file. Source this file after yaml.sh of the harness; it expects root, the
# repository's directory.

: "${root:?}"
readonly SCORECARD_RULES=$root/tests/lib/scorecard.jq

# scorecard_violations PATH: print the violations of the rules by the workflow
# at PATH, in the repository, one per line; fails when the file cannot be
# read.
scorecard_violations() {
  local path=$1
  load_yaml "$path" | jq -r -f "$SCORECARD_RULES"
}

# scorecard_broken_rules PATH: print the rules the workflow at PATH, in the
# repository, breaks, sorted and separated by spaces.
scorecard_broken_rules() {
  local path=$1
  scorecard_violations "$path" | cut -d: -f1 | sort -u | paste -sd' ' -
}
