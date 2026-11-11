# workflow-scorecard

A reusable GitHub Actions workflow that runs [OpenSSF Scorecard][scorecard] for
flakeyard repositories and for projects generated from flakeyard templates. It
publishes the results of the calling repository and uploads them to its code
scanning.

## Usage

Call it from the repository's only Scorecard workflow, `scorecard.yaml`, on
pushes to the default branch, on a schedule and on dispatch:

<!-- markdownlint-disable MD013 -->

```yaml
# .github/workflows/scorecard.yaml
name: scorecard

on:
  push:
    branches: [main] # the default branch
  schedule:
    - cron: "41 3 * * 1"
  workflow_dispatch:

permissions: {}

jobs:
  scorecard:
    uses: flakeyard/workflow-scorecard/.github/workflows/scorecard.yaml@<commit> # v0.1.0
    permissions:
      actions: read # workflow runs, needed in private repositories
      contents: read # checkout and the repository through the API
      id-token: write # signs the published results
      security-events: write # uploads the results to code scanning
```

<!-- markdownlint-enable MD013 -->

Reference the workflow by full commit SHA with the version in a comment, as
above, and let Renovate update both. A tag also works, but Scorecard counts a
reusable workflow referenced by tag as an unpinned dependency, and the
repository loses points of the Pinned-Dependencies check. The calling job must
grant exactly these four permissions, and the workflow none at the top level.

The published results are shown by the badge
`https://api.scorecard.dev/projects/github.com/<owner>/<repo>/badge`, for
example in the README:

```markdown
[![OpenSSF Scorecard][scorecard-badge]][scorecard-viewer]

[scorecard-badge]:
  https://api.scorecard.dev/projects/github.com/<owner>/<repo>/badge
[scorecard-viewer]: https://scorecard.dev/viewer/?uri=github.com/<owner>/<repo>
```

## Behaviour

- **Default branch only.** The job runs when the ref of the run is the default
  branch of the repository, and for every scheduled run, which always runs on
  it; on any other ref it is skipped. The Scorecard server accepts results only
  for the default branch.
- **Steps.** The job checks out the repository without keeping credentials, runs
  [scorecard-action][scorecard-action] with `publish_results: true` and uploads
  its SARIF results to the code scanning of the repository.
- **Verification.** The results are signed with the identity of this workflow
  file. Before it accepts them, the Scorecard server fetches this file at the
  ref of the call and checks its content, not the caller's file; this file
  therefore holds only the Scorecard job and changes only within the rules of
  the server.

The workflow takes no inputs and no secrets and has no outputs.

## Requirements

GitHub-hosted Ubuntu runners. Scorecard runs on public repositories; private
ones need GitHub Advanced Security and read permissions this workflow does not
grant.

## Development

The product workflow,
[`.github/workflows/scorecard.yaml`](.github/workflows/scorecard.yaml), is also
this repository's own Scorecard workflow: its triggers `push`, `schedule` and
`workflow_dispatch` run it here, and callers reach it through `workflow_call`. A
repository runs Scorecard from exactly one workflow, so this one does not call
itself by commit.

The repository checks itself with [`test.yaml`](.github/workflows/test.yaml),
which calls [workflow-check][workflow-check] after a job that pins
[action-shell-lib][action-shell-lib]. workflow-check builds the checks of the
repository's flake: `tests/run.sh`, the static tests of the workflows
(`checks.unit`), shellcheck and shfmt over the scripts (`checks.shell`) and
nixfmt over the Nix files (`checks.formatting`). The tests use the harness of
`internal/testing` of action-shell-lib at the commit that `test.yaml` pins:
`checks.unit` fetches it, and a local run of `tests/run.sh` fetches it once into
`~/.cache/flakeyard/action-shell-lib`. The suites in `tests/unit/workflows` have
one file per workflow, run on `workflow.sh` of `internal/testing` and share the
helpers in `tests/lib`; `tests/unit/workflows/scorecard.sh` checks that the
product workflow meets the rules below, its triggers, its condition and its
steps.

`tests/lib/scorecard.jq` holds the rules a Scorecard workflow must meet, as
named `def`s: the rules the Scorecard server verifies before it accepts results
([`verify_workflow.go`][verify-workflow]), and those of [FY-0034][fy-0034]:
`permissions: {}` at the top level, only the Scorecard job, exactly its four
permissions and every action pinned by full commit SHA. The server also checks
that each pinned commit belongs to its action's repository; that needs the API
and is not tested here. `tests/unit/lib/scorecard.sh` runs the rules on the
workflows in `tests/fixtures/scorecard`: the valid ones break none, and each of
the others breaks exactly the rules its first line names.

The suites read the workflows with mikefarah `yq` v4 and fail without it;
locally, run `nix shell nixpkgs#yq-go -c tests/run.sh`. Before a pull request,
run `nix flake check`, actionlint, zizmor, prettier, markdownlint, typos and
`reuse lint`.

The repository releases itself with [workflow-release][workflow-release] through
[`release.yaml`](.github/workflows/release.yaml), whose release pull requests
are checked by a dispatched run of `test.yaml`. The weekly workflow
[`maintenance.yaml`](.github/workflows/maintenance.yaml), which is not a
required check, runs `nix run .#check-eol -- nixpkgs-eol`
([`scripts/check/eol.sh`](scripts/check/eol.sh)): it warns from 30 days before
the end of life of the nixpkgs branch in `nixpkgs-eol` and fails after it,
following [FY-0026][fy-0026]; `tests/unit/scripts` tests the script. The design
follows [FY-0034][fy-0034] and [FY-0030][fy-0030].

## Bootstrap

Following [FY-0022][fy-0022], some checks of this repository are not released
yet. Until they are:

- actionlint, zizmor, prettier, markdownlint, typos and REUSE run locally before
  every pull request; the atoms will provide them.

## License

[MIT](LICENSE).

[scorecard]: https://github.com/ossf/scorecard
[scorecard-action]: https://github.com/ossf/scorecard-action
[verify-workflow]:
  https://github.com/ossf/scorecard-infra/blob/main/api/app/server/verify_workflow.go
[action-shell-lib]: https://github.com/flakeyard/action-shell-lib
[workflow-check]: https://github.com/flakeyard/workflow-check
[workflow-release]: https://github.com/flakeyard/workflow-release
[fy-0022]:
  https://github.com/flakeyard/decisions/blob/main/docs/adr/records/0022-bootstrap.md
[fy-0026]:
  https://github.com/flakeyard/decisions/blob/main/docs/adr/records/0026-stable-nixpkgs.md
[fy-0030]:
  https://github.com/flakeyard/decisions/blob/main/docs/adr/records/0030-actions-workflows-and-release-bot.md
[fy-0034]:
  https://github.com/flakeyard/decisions/blob/main/docs/adr/records/0034-check-every-repository-with-workflow-check.md
