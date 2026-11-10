# shellcheck shell=bash
# shellcheck disable=SC2016 # jq expressions, not expansions.
# Static tests of the product workflow: it meets the rules of the Scorecard
# server and of FY-0034, and runs Scorecard only on the default branch.

: "${root:?}"

# The condition of the job: only the default branch; schedule events have no
# repository in their payload and always run on it.
readonly SCORECARD_CONDITION="\${{ github.event_name == 'schedule' || github.ref == format('refs/heads/{0}', github.event.repository.default_branch) }}"
readonly SCORECARD_STEPS='["actions/checkout","ossf/scorecard-action","github/codeql-action/upload-sarif"]'

# product_test NAME FILTER: FILTER is true of scorecard.yaml.
product_test() { workflow_check "$product_workflow" "scorecard.yaml: $1" "$2"; }

# product_meets_rules: scorecard.yaml breaks none of the Scorecard rules.
product_meets_rules() {
  setup
  run_lib "scorecard.yaml: meets the rules of the Scorecard server and of FY-0034" ok "" \
    scorecard_violations .github/workflows/scorecard.yaml
  expect stdout ""
  finish
}

if require_yq scorecard.yaml && require_workflow scorecard.yaml; then
  product_workflow=$(load_workflow scorecard.yaml)
  product_meets_rules
  product_test "callers pass no inputs and no secrets, and get no outputs" \
    '.on | has("workflow_call") and .workflow_call == null'
  product_test "this repository runs it on main, weekly and on dispatch" \
    '.on | .push == {"branches":["main"]} and (.schedule | length == 1) and has("workflow_dispatch")'
  product_test "the job runs only on the default branch" \
    ".jobs.scorecard | condition == \"$SCORECARD_CONDITION\""
  product_test "the job runs on ubuntu-24.04 with a timeout" \
    '.jobs.scorecard | .["runs-on"] == "ubuntu-24.04" and (.["timeout-minutes"] | type == "number")'
  product_test "checkout, Scorecard and the upload, in this order" \
    "[.jobs.scorecard.steps[].uses | sub(\"@.*\$\"; \"\")] == $SCORECARD_STEPS"
  product_test "checkout keeps no credentials" \
    '.jobs.scorecard.steps[0].with == {"persist-credentials": false}'
  product_test "Scorecard publishes its results as SARIF" \
    '.jobs.scorecard.steps[1].with
    == {"results_file":"results.sarif","results_format":"sarif","publish_results":true}'
  product_test "the upload sends the results of Scorecard" \
    '.jobs.scorecard.steps
    | .[2].with == {"sarif_file": .[1].with.results_file}'
fi
