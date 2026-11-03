# shellcheck shell=bash
# Static tests of the release workflow of this repository.
# shellcheck disable=SC2016 # jq expressions, not expansions.

: "${root:?}"

# release_test NAME FILTER: FILTER is true of release.yaml.
release_test() { workflow_check "$release_workflow" "release.yaml: $1" "$2"; }

if require_yq release.yaml && require_workflow test.yaml; then
  release_workflow=$(load_workflow release.yaml)
  release_test "no permissions at the top level" '.permissions == {}'
  release_test "workflow-release is pinned by commit" \
    '.jobs.release.uses | test("^flakeyard/workflow-release/\\.github/workflows/release\\.yaml@[0-9a-f]{40}$")'
  release_test "release pull requests are checked by the CI of this repository" \
    '.jobs.release.with | .["check-workflow"] == "test.yaml" and .["app-pull-requests"] == false'
fi
