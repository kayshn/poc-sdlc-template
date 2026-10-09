# TODO

Deferred work on the template itself. Not part of the standard a consumer receives.

## Known defects

None outstanding. The four recorded here were fixed in `v1.7.0`: `open_pr.sh` discarding generated
work on failure, reporting a push rejection as a bare `exit 128`, opening a pull request that could
never merge when two runs raced, and the build agent being told to run checks it was not permitted
to run.

Two notes survive those fixes:

- **`.claude/settings.json` and `claude.yml` are project-owned**, so the permission half of that
  last fix does not reach a repository created before `v1.7.0`. Such a repository must add
  `Bash(make flow-check)` and `Bash(make template-check)` itself.
- **`--unless` guards the artefact, not the agent run.** The losing run still generates a spec and
  pays for it before bowing out. Stopping earlier would mean checking at the start, which races
  differently.

## Untested

- **`@claude fix this`.** The iterate path in stage 4 has never been exercised. Everything else in
  the loop has now run at least once.
- **Stage 6, maintain.** `monitor.yml` and the σ-breach path have never run.

## Script the GitHub settings (`setup_github.sh`)

Two gates — the `production` environment's required reviewers, and *allow Actions to create and
approve pull requests* — exist in no file in the repo. A team that misses them gets a pipeline that
looks green and deploys to production with no human gate: a safety failure disguised as success, and
invisible to `make template-check`. [SDLC-GUIDE.md](SDLC-GUIDE.md) step 4 states them as prose, which
is the same mistake `.sdlc/flow.yaml` exists to avoid.

Proposed: `.sdlc/scripts/setup_github.sh`, in the invariant layer.

```bash
./.sdlc/scripts/setup_github.sh --verify                  # read-only; safe for CI and the scorecard
./.sdlc/scripts/setup_github.sh --apply --approvals 0
```

| Step | Scriptable | Endpoint |
|---|---|---|
| Install the Claude GitHub App | no — interactive consent, no API | — |
| `CLAUDE_CODE_OAUTH_TOKEN` | value is human-sourced | `gh secret set` from stdin, never logged |
| `SDLC_BOT_TOKEN` | fine-grained PATs cannot be minted by API | `gh secret set` from stdin, never logged |
| Actions may create and approve PRs | yes | `PUT /repos/{o}/{r}/actions/permissions/workflow` |
| Allow auto-merge | yes | `gh repo edit --enable-auto-merge` |
| `production` environment + reviewers | yes | `PUT /repos/{o}/{r}/environments/production` |
| Protect `main` | yes | `POST /repos/{o}/{r}/rulesets`, checks `ci / test` and `evals / suite` |

Design constraints:

- **`--verify` is the durable half.** A one-way apply gets run once and then drifts; the read-only
  check is what belongs in `check_template.sh` and the scorecard.
- **Only ever tighten.** A re-run must never remove a team's stricter rule. Assert and report, never
  sync down.
- **`--approvals` must be a parameter.** Hard-coding one required approval deadlocks any repo with a
  single maintainer, because GitHub forbids approving your own PR.
- **Report, do not pretend.** The three steps it cannot finish must be detected and named.
- **A local script, not a `bootstrap.yml` workflow.** A workflow would need an admin-scoped PAT
  stored as a repo secret in order to configure secrets — chicken-and-egg — and would leave every
  consumer holding a credential that can rewrite its own branch protection. Running locally against
  the adopter's own `gh` auth means no admin credential is stored anywhere.

## Also deferred

- **Eval cases need a positive control.** `run_evals.sh` now fails a case whose agent run errored
  (v1.3.0), which closes the specific hole found on 2026-10-08. The shape of the problem remains:
  `intent-is-frozen-during-build` asserts `git diff --quiet -- .sdlc/intent/`, and *any* agent that
  does nothing satisfies it. Every negative assertion should be paired with a positive one — the
  agent must be shown to have done the permitted part of the task while being blocked from the
  forbidden part. Until then a case can only prove "nothing bad happened", not "the hook blocked it".
- **Conformance scorecard.** Scheduled job across repos with topic `ai-sdlc`, publishing template
  version, gates present and eval pass rate. `check_template.sh --verify` output is the input.
- **Support a private template source.** `sdlc_update.sh` fetches with anonymous
  `curl https://codeload.github.com/...` and `latest_tag` uses anonymous `git ls-remote`. Both fail
  against a private template, so any team unwilling to publish its standard cannot adopt this.
  Both should read `GH_TOKEN` or `SDLC_BOT_TOKEN` and fall back to anonymous.

  Fixing that alone is not enough. **A public repository cannot call a private repository's
  reusable workflow**, even with Settings → Actions → Access set to *accessible from repositories
  owned by the user*: that setting shares with private repositories only. Verified on 2026-10-08 —
  a dispatch failed to parse with `workflow was not found` 45 seconds after the setting was
  applied. So the visibility of the template constrains the visibility of every consumer:

  | Template | Consumer | Result |
  |---|---|---|
  | public | public | works |
  | public | private | works; needs a paid plan for `production` environment reviewers |
  | private | private | needs the token fix above, and a paid plan |
  | private | **public** | **impossible** |

  The last row is the one to warn adopters about, because the free-plan trap compounds it: a
  private consumer on GitHub Free silently loses its `production` environment protection rules,
  which is the stage-5 release gate.
- **Template-upgrade PRs get no AI review.** `claude-code-action` refuses to run when a workflow
  file differs from the version on the default branch. `sdlc_update.sh` rewrites the pinned refs in
  the callers, so every upgrade PR trips that check. CI and evals still run; only the review is
  skipped. Either accept it, or move the pinned ref out of the workflow and into a file the
  workflow reads.
- **`copier` for layer 2.** `sdlc_update.sh` only carries the invariant layer. If the seeded files
  (`CLAUDE.md`, the `_TEMPLATE.md` artefacts, the thin callers) ever need to receive upstream
  improvements after creation, `copier update` three-way-merges via `.copier-answers.yml`.
  Cookiecutter has no update story.
- **Yank `v1.0.0`.** Its first install aborts silently; fixed in `v1.0.1`. The release notes say so,
  but nothing stops `sdlc_update.sh v1.0.0`.
- **`make install` provisioning is unproven beyond Python.** The claim that the Makefile is the only
  seam needs a second consumer on a different stack to hold up.


## K1
- Evaluate using Copilot instead of Claude
- Evaluate AWS SDLC
- Improve evals and measuring agent performance
- Measure value from using DLC
- Clarify how versioning works in template and consumer works
- Add some engineering guardrails
- Update spec step to create and update C4 diagrams if necessary
- Test the monitor stage
- Have a check in pipeline to fail any build that uses old DLC version