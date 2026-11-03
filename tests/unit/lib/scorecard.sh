# shellcheck shell=bash
# Tests of the Scorecard rules: every fixture in tests/fixtures/scorecard
# breaks exactly the rules listed for it, and the valid ones break none.

: "${root:?}"
readonly SCORECARD_FIXTURES=$root/tests/fixtures/scorecard
tested_fixtures=()

# fixture_test FIXTURE [RULE...]: the workflow FIXTURE.yaml breaks exactly
# the rules RULE..., or none.
fixture_test() {
  local fixture=$1
  shift
  local expected actual
  expected=$(printf '%s\n' "$@" | sort -u | paste -sd' ' -)
  tested_fixtures+=("$fixture.yaml")
  start "scorecard rules: $fixture"
  if ! actual=$(scorecard_broken_rules "$SCORECARD_FIXTURES/$fixture.yaml"); then
    report "the rules failed on $fixture.yaml"
  elif [[ $actual != "$expected" ]]; then
    report "breaks '$actual', expected '$expected'"
  fi
  finish
}

# every_fixture_tested: no fixture is left without a test.
every_fixture_tested() {
  local untested
  untested=$(comm -23 <(cd -- "$SCORECARD_FIXTURES" && printf '%s\n' *.yaml | sort) \
    <(printf '%s\n' "${tested_fixtures[@]}" | sort))
  start "scorecard rules: every fixture is tested"
  [[ -z $untested ]] || report "untested fixtures: $untested"
  finish
}

if require_yq scorecard-rules; then
  fixture_test valid
  fixture_test latest-runner
  fixture_test oldest-runner
  fixture_test top-level-env top-level-env-or-defaults
  fixture_test top-level-defaults top-level-env-or-defaults
  fixture_test write-all top-level-write top-level-permissions
  fixture_test top-level-write top-level-write top-level-permissions
  fixture_test top-level-read top-level-permissions
  fixture_test no-scorecard-job scorecard-job
  fixture_test second-job one-job
  fixture_test id-token-elsewhere id-token-elsewhere one-job
  fixture_test container container-or-services
  fixture_test services container-or-services
  fixture_test runner-labels runner-count
  fixture_test old-runner runner-label
  fixture_test other-runner runner-label
  fixture_test job-env job-env
  fixture_test job-defaults job-defaults
  fixture_test run-step step-uses
  fixture_test other-action step-allowed
  fixture_test unpinned pinned
  fixture_test extra-permission job-permissions
  fixture_test missing-permission job-permissions
  every_fixture_tested
fi
