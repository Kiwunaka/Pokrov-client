# Required Checks

This page records the checks maintainers should require before merging source
changes or publishing source-only releases. It is a repository policy document,
not proof that GitHub branch protection settings are already enabled on the
remote repository.

The machine-readable policy is
[`config/required-checks.seed.json`](../config/required-checks.seed.json). The
active CI workflow is [`.github/workflows/ci.yml`](../.github/workflows/ci.yml).
GitHub repository ruleset and branch protection setup is tracked separately in
[`GITHUB_RULESET_SETUP.md`](GITHUB_RULESET_SETUP.md) and
[`config/github-ruleset.seed.json`](../config/github-ruleset.seed.json).

## Pull Request Checks

Pull requests should keep these CI jobs green:

- `Source import and public tree checks`
- `Flutter analyze and tests`

The workflow should keep read-only repository permissions, including
`contents: read`.

The source-import job covers Python contract tests, operator fixture smoke,
seed validation, contributor doctor smoke, source-release preflight smoke,
source-import dry-run, white-label token smoke, and clean-clone source-boundary
proof.

The Flutter job covers workspace bootstrap, shared app-shell analysis, and the
workspace Flutter test lane.

## GitHub Settings Guidance

When configuring branch protection or repository rulesets in GitHub settings,
maintainers should require:

- pull requests before merge
- the two CI job names above
- up-to-date branches when practical for the stacked PR flow
- CODEOWNERS review for sensitive paths when the repository policy requires it
- conversation resolution before merge

Do not describe a branch as protected, required, or enforced in release notes
unless the repository settings have actually been configured and observed.

## Source Release Gate

Before publishing a source-only release, run the full local gate on the exact
annotated source tag:

```powershell
python -m pytest tests
powershell -ExecutionPolicy Bypass -File .\scripts\validate-seed.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\run-tests.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\source-release-preflight.ps1 -RequireTag
powershell -ExecutionPolicy Bypass -File .\scripts\verify-clean-clone.ps1
```

CI smoke coverage is not a publishing gate. In particular,
`source-release-preflight.ps1 -SkipTestCommands` is allowed for CI smoke only
and must not be used for a public source release.

## Release Boundary

Green checks do not claim APK, EXE, store release, trusted signing, official
binary readiness, runtime binary review, private backend readiness, or operator
production readiness. They only prove the public source gate described here.
