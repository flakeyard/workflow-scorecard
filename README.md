# workflow-scorecard

A reusable GitHub Actions workflow that runs [OpenSSF Scorecard][scorecard] for
flakeyard repositories and for projects generated from flakeyard templates. It
publishes the results of the calling repository and uploads them to its code
scanning.

The workflow is not released yet; its usage is described here with the first
release.

## Development

The repository checks itself with [`test.yaml`](.github/workflows/test.yaml),
which calls [workflow-check][workflow-check] as its only job. workflow-check
builds the checks of the repository's flake: `tests/run.sh`, the static tests of
the workflows (`checks.unit`), shellcheck and shfmt over the scripts
(`checks.shell`) and nixfmt over the Nix files (`checks.formatting`). The suites
in `tests/unit/workflows` have one file per workflow and share the helpers in
`tests/lib`. They read the workflows with mikefarah `yq` v4 and fail without it;
locally, run `nix shell nixpkgs#yq-go -c tests/run.sh`. Before a pull request,
run `nix flake check`, actionlint, zizmor, prettier, markdownlint, typos and
`reuse lint`.

The repository releases itself with [workflow-release][workflow-release] through
[`release.yaml`](.github/workflows/release.yaml), whose release pull requests
are checked by a dispatched run of `test.yaml`. The design follows
[FY-0031][fy-0031] and [FY-0030][fy-0030].

## Bootstrap

Following [FY-0022][fy-0022], some checks of this repository are not released
yet. Until they are:

- actionlint, zizmor, prettier, markdownlint, typos and REUSE run locally before
  every pull request; the atoms will provide them;
- rulesets require no status checks until every repository has adopted
  workflow-check;
- OpenSSF Scorecard comes with the workflow of this repository.

## License

[MIT](LICENSE).

[scorecard]: https://github.com/ossf/scorecard
[workflow-check]: https://github.com/flakeyard/workflow-check
[workflow-release]: https://github.com/flakeyard/workflow-release
[fy-0022]:
  https://github.com/flakeyard/decisions/blob/main/docs/adr/records/0022-bootstrap.md
[fy-0030]:
  https://github.com/flakeyard/decisions/blob/main/docs/adr/records/0030-actions-workflows-and-release-bot.md
[fy-0031]:
  https://github.com/flakeyard/decisions/blob/main/docs/adr/records/0031-check-pull-requests-and-pushes-with-workflow-check.md
