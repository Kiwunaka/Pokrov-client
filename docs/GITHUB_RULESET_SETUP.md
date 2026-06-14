# GitHub Ruleset Setup

This page is the maintainer checklist for configuring GitHub repository
rulesets or branch protection for the public source lane. It is not proof that remote GitHub settings are already active.

The machine-readable setup contract is
[`config/github-ruleset.seed.json`](../config/github-ruleset.seed.json). The
required CI job names live in
[`config/required-checks.seed.json`](../config/required-checks.seed.json) and
[`REQUIRED_CHECKS.md`](REQUIRED_CHECKS.md).

The read-only verifier is
[`scripts/check-github-ruleset.ps1`](../scripts/check-github-ruleset.ps1). It
uses `gh api` to inspect repository rulesets and branch protection. It does not create, edit, or delete GitHub settings.

## Preferred Setup

Use a repository ruleset for `main` when available. A branch protection rule is
an acceptable fallback when rulesets are unavailable for the account or
repository.

Require:

- pull request before merge
- required status checks:
  - `Source import and public tree checks`
  - `Flutter analyze and tests`
- CODEOWNERS review for matching paths
- conversation resolution before merge
- blocked force pushes
- blocked branch deletion

Keep bypass actors explicit and minimal. Do not add broad bypass permissions
unless a maintainer records why the exception is needed.

## Manual Verification

After configuring GitHub settings, record the verification in the release
handoff or maintainer notes:

- repository ruleset or branch protection is active for `main`
- required status checks exactly match `config/required-checks.seed.json`
- CODEOWNERS review is required for matching paths
- conversations must be resolved before merge
- force pushes and branch deletion are blocked for protected targets
- a test pull request without required checks cannot be merged

Run the verifier after manual setup:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\check-github-ruleset.ps1 `
  -Repository Kiwunaka/Pokrov-client `
  -Branch main
```

For a non-blocking status report before settings exist, use `-ReportOnly
-Json`. A failing verifier is expected until a maintainer configures GitHub
rulesets or branch protection.

Until that observation exists, public docs and release notes must keep saying
that this repository documents the expected setup, not that GitHub enforcement
is active.

## Source Release Boundary

GitHub ruleset or branch protection settings do not prove APK, EXE, store release, trusted signing, official binary readiness, runtime binary review, private backend readiness, or operator production readiness.

They only protect the source merge path. Source releases still require the
source-only checklist, proof manifest, rendered release notes, and clean-clone
checks.

## References

- [GitHub rulesets overview](https://docs.github.com/en/repositories/configuring-branches-and-merges-in-your-repository/managing-rulesets/about-rulesets)
- [GitHub ruleset rules](https://docs.github.com/en/repositories/configuring-branches-and-merges-in-your-repository/managing-rulesets/available-rules-for-rulesets)
- [GitHub protected branches](https://docs.github.com/repositories/configuring-branches-and-merges-in-your-repository/managing-protected-branches/about-protected-branches)
