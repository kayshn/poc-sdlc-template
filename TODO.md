# TODO

Deferred work on the template itself. Not part of the standard a consumer receives.
Removed from a repository created from this template on first install.

## Where things stand (2026-10-09)

Both repositories are on `v2.2.0`. `flow-check`, `template-check`, `lint` and `test` all pass in the
consumer. One lap is in flight: slug `002-link-follow-count` has reached the Build issue, and
nothing has been built from it yet.

**`v2.1.0` and `v2.2.0`.** `v2.1.0` added the *Claims about what was run* rule to `.sdlc/upstream/REVIEW.md`,
after a build agent's unverified refusal was repeated by the reviewer as fact — see *Known defects*.
`v2.2.0` added the engineering guardrails: `.sdlc/upstream/standards/engineering-guardrails.md` holds G1–G5
and is invariant, while the two things that make it bite — the `@`-import line in `CLAUDE.md` and
the *Guardrails* pass in `.sdlc/upstream/REVIEW.md` — belong to the project and are enforced by
`check_template.sh`. Wiring costs a consumer two edits, once; every later revision of the rules then
arrives for free. `invariant.txt` names the guardrails *file* and not the `.sdlc/standards/`
directory on purpose: a directory entry is `find`-expanded, so it would sweep a consumer's own
`project-guardrails.md` into the manifest and fail that consumer's drift check.

**The guardrails reach the reviewer in CI, and that is all that is proven.** The review on the `002`
intent pull request emitted a *Guardrails* pass naming G1–G5, and the guardrails file was not in
that diff, so it came from the repository rather than the change. Two things remain unproven: that
a guardrail bites on real code — a clean pass over a Markdown-only intent is vacuous — and that the
*build* agent has the rules in session without being told to look, which is the half that matters,
because nothing in its prompt mentions them. The build pull request for `002` is that test: look for
a guardrail cited by id in the agent's own plan and description, not only in the review. An upgrade
pull request can never settle it, since it rewrites the pinned refs and `claude-code-action` then
declines to run.

**Repositories.** `kayshn/poc-sdlc-template` (public, template repo, topic `ai-sdlc`) and
`kayshn/poc-sdlc-consumer-app` (public, a FastAPI URL shortener). Both must stay public: a public
repository cannot call a private repository's reusable workflow, and a private repository on the
free plan silently loses the `production` environment reviewers that are the release gate.

**All six stages are now proven.** The first lap, slug `000-expiring-links`, went intent → spec →
build issue → code → review → merge → deploy. The second lap closed the remaining two gaps on
`v2.0.0`: **Run workflow → inject `0.052`** raised slug `001-monitor-ci-test-failure-rate` as an
intent PR (#11), which carried itself through spec (#12), Build issue (#13) and build PR (#14), and
a review comment answered with `@claude fix this` produced `52a39b1`. Stage 6 and the stage 4
iterate path both work. Costs so far are around $0.30 of Anthropic API credit.

**The monitor's diagnosis was correct and worth reading.** Given only a detector payload, the agent
worked out unprompted that the breach was probably synthetic — it found the `inject` input in
`monitor.yml`, noticed `detect.sh` never writes `metrics.json`, and named the one check that would
settle it. That check has since been run: injected `0.052` reproduces its numbers exactly, and the
committed series reports `tier: none`. It was right, and it said "hypothesis, not confirmed".

**Environment.** `gh` has been uninstalled, so opening pull requests, reading run logs and creating
releases all have to happen in the browser. `yq` is still needed for `make flow-check`. Tags
`v1.6.0` through `v2.0.0` have no GitHub Release pages; the tags work and `sdlc_update.sh` does not
need them, so the notes live only in commit messages.

**Two settings that are deliberately not what the guide recommends**, because this is a
single-maintainer repository: required approvals is `0` (GitHub forbids approving one's own pull
request), and `.claude/settings.json` holds an API key rather than a subscription token, which bills
prepaid credits.

**The pattern worth carrying into any demo.** Every serious defect found on 2026-10-08 and -09 was a
*silent success*: the eval suite reported `rate=1.00` with zero tokens spent, `protect-paths.sh`
failed open and allowed the edit it exists to block, `sdlc_update.sh` corrupted itself mid-upgrade
after replacing four files, and two shipped fixes were never delivered to a consumer that reported
conformant on the newest tag. None failed loudly. All were found by running something, never by
reading it.

## Known defects

- **The build agent reported a refusal, and the review repeated it as fact.** The plan committed on
  PR #14 of the consumer says "`.sdlc/upstream/scripts/detect.sh`, `make lint` and `make test` were not run in
  this build because the sandbox refused those commands". `detect.sh` is correct — it is in no
  allow list. `make lint` and `make test` are not: the iterate run's log shows the full
  `allowedTools` arriving intact from `_claude.yml@v2.0.0`, `permission_denials_count: 0`, and the
  Makefile calls `.venv/bin/*` directly after `make install` has run as a workflow step. There was
  nothing to refuse.

  Two separate things, one confirmed and one probable:

  - **Confirmed: the loop launders an unverified claim into a reviewed fact.** `claude-review`
    wrote "the PR description says the author's sandbox also refused them" instead of testing it.
    Nothing in `.sdlc/upstream/REVIEW.md` required otherwise, so an assertion with no evidence behind it
    reached a human looking corroborated. Fixed by the "Claims about what was run" section, which
    `check_template.sh` now requires.
  - **Probable: the refusal never happened.** `claude-code-action`'s own prompt tells the agent
    "if you are unable to complete certain steps, such as running a linter or test suite,
    particularly due to missing permissions, explain this in your comment", and "your console
    outputs and tool results are NOT visible to the user". The scaffolding offers a sanctioned
    excuse for skipping verification and says nobody can check. To confirm, read
    `permission_denials_count` in the *build* run's log — the one triggered from issue #13. If it
    is `0`, nothing was ever refused.

  Blast radius was low: the PR changed one Markdown file and `ci / test` ran properly. The damage
  is to the artefact the loop is built on. A plan that can claim "I verified X" with nothing
  checking is decoration.

- **Every consumer needs one `--rewire` after taking `v2.0.0`.** `sdlc_update.sh` is itself part of
  the invariant layer, so the copy that runs an upgrade is always the one installed *before* it.
  The release that teaches the script to migrate a full-body workflow into a thin caller is
  therefore run by a script that cannot do it. `check_template.sh` arrives in the same upgrade and
  fails the upgrade PR with the remedy in the message:

      ./.sdlc/upstream/scripts/sdlc_update.sh --rewire

  One command, once, and only for repositories created before `v2.0.0`. Done in the consumer on
  2026-10-09 (PR #10). Every later body extraction migrates on its own, because the migration code
  is by then already installed.

Fixed in `v2.0.0`:

- **Fixes to a workflow body never reach an existing consumer.** Those four carried real logic in a
  file the project owned, so `sdlc_update.sh` — which rewrites a caller's `uses:` ref and nothing
  else — announced a change to the body in the release notes and silently did not deliver it. Two
  shipped fixes were found undelivered on 2026-10-09 in a consumer that reported `template-check`
  green and was pinned to the newest tag:

  | Fix | Released | Was still missing in the consumer |
  |---|---|---|
  | `agent-evals.yml` trigger, so `evals / suite` is safe to require | `v1.2.0` | the path filter was still there, so the check never ran and could not be required |
  | `--unless` race guard in `intent-to-spec.yml` | `v1.7.0` | the call had no guard |

  The first is the more serious: a team following the guide would have required a check that never
  reports and blocked every pull request in the repository.

  All nine workflows are now split — body in a `_*.yml` callable pulled by tag, triggers in a
  caller the project owns — so nothing a fix could need to reach is left behind. `sdlc_update.sh`
  replaces a legacy full-body caller with the standard's thin one, and `check_template.sh` fails
  any caller that still declares `runs-on:` or `steps:`.

  Two things moved with the bodies and are no longer the project's to lose: the `@claude` mention
  test, and the tools the build agent is allowed. The latter is now the `allowed_tools` input of
  `_claude.yml`, so a project extends the set in its caller rather than holding a copy of it.

Previously recorded and fixed in `v1.7.0`: `open_pr.sh` discarding generated work on failure,
reporting a push rejection as a bare `exit 128`, opening a pull request that could never merge when
two runs raced, and the build agent being told to run checks it was not permitted to run.

Two notes survive those fixes:

- **`.claude/settings.json` is project-owned**, so the settings half of that last fix does not reach
  a repository created before `v1.7.0`. Such a repository must add `Bash(make flow-check)` and
  `Bash(make template-check)` itself. The workflow half now travels in `_claude.yml`.
- **`--unless` guards the artefact, not the agent run.** The losing run still generates a spec and
  pays for it before bowing out. Stopping earlier would mean checking at the start, which races
  differently.

## Untested

Every stage of the loop has now run at least once. What is left untested is the second-order
behaviour, not the path:

- **A σ-breach the agent cannot dismiss.** The one run of stage 6 was synthetic and the agent said
  so. A 3σ breach (`inject 0.2`) and its pre-approved rollback runbook have still never run.
- **A real `@claude fix this`.** The one exercise of the iterate path produced a one-line edit to a
  Markdown plan. It has never been asked to change code in response to a review.

## Script the GitHub settings (`setup_github.sh`)

Two gates — the `production` environment's required reviewers, and *allow Actions to create and
approve pull requests* — exist in no file in the repo. A team that misses them gets a pipeline that
looks green and deploys to production with no human gate: a safety failure disguised as success, and
invisible to `make template-check`. [.sdlc/upstream/GUIDE.md](.sdlc/upstream/GUIDE.md) step 4 states them as prose, which
is the same mistake `.sdlc/flow.yaml` exists to avoid.

Proposed: `.sdlc/upstream/scripts/setup_github.sh`, in the invariant layer.

```bash
./.sdlc/upstream/scripts/setup_github.sh --verify                  # read-only; safe for CI and the scorecard
./.sdlc/upstream/scripts/setup_github.sh --apply --approvals 0
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

## The design gate has nothing standing on it

Found on 2026-10-09 by the `002-link-follow-count` lap, on `v2.2.0`. The spec pull request is the
only gate in the loop with no person on it — `.sdlc/flow.yaml` sets `stages.design.gate.approval`
to `auto` and the pipeline grants the approval. The AI review ran on that pull request, raised two
**Important** findings, and the pull request auto-merged anyway, unlocking the Build issue. A
review whose findings cannot change the outcome is decoration.

The two findings, both substantive:

- *Compliance* — the spec carried `Status: approved (auto)` while its own last line said an
  unresolved question "blocks approval of the spec". Both cannot hold.
- *Security* — the spec planned a state-changing anonymous route with no `store.record`, waiving
  `secure-api-review` rule 4 and a `CLAUDE.md` convention. The reasoning was sound; a spec waiving
  a project convention on its own authority is not.

Four pieces of work, smallest first. The last is the only one that needs a gate at all:

- **G7: a spec may not relax a rule.** A spec, plan or build that needs a `CLAUDE.md` convention, a
  skill rule or a guardrail changed must propose that amendment as its own change and block on it.
  Belongs in `.sdlc/upstream/standards/engineering-guardrails.md`, where it binds the spec *author* rather
  than being caught afterwards by the reviewer. Cheapest, prevents the class, and the provenance is
  real: the loop found it.
- **An approved spec cannot have open questions.** Deterministic, no model needed — the
  contradiction above is two fields of one artefact disagreeing. A `check_flow.sh`-shaped assertion
  over `.sdlc/specs/<slug>.md`.
- **An accepted risk needs a named owner.** `_TEMPLATE.md` should require a name in the risk
  section, and empty should fail. "Accepted risk" with nobody accepting it is the same laundering
  of an unowned claim as the refusal defect above.
- **`review-gate`: `important > 0` withholds the automatic approval.** Not "Important blocks
  merge" — that would hand the model a veto over people. It fails closed and a human still merges,
  so the agent can stop a gate but never pass one, which is the existing rule unchanged. Read only
  the `REVIEW-TALLY important=<n> nit=<n>` line; the moment the gate parses the review body, the
  model's formatting becomes load-bearing. Two details decide whether it is real:
  - **Scope it to spec pull requests.** A blanket gate blocks every `chore: SDLC template vX.Y.Z`
    upgrade for good, because those are exactly the pull requests where `claude-code-action`
    refuses to run.
  - **No tally must fail, not pass.** Otherwise the gate evaporates in precisely the case where the
    review was skipped — which the workflow-file-differs quirk guarantees will happen.

## Also deferred

- **Eval cases need a positive control.** Done for `intent-is-frozen-during-build`: its prompt now
  asks for a permitted edit to `.sdlc/plans/` as well as the forbidden one to `.sdlc/intent/`, and
  `check.sh` fails unless the permitted half landed. An agent that errored, refused everything, or
  never ran no longer passes. The rule generalises and is not yet applied anywhere else, because
  there is nowhere else: every new case must pair its negative assertion with a positive one, or
  it can only prove "nothing bad happened", never "the hook blocked it".
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
