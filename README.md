# AI-native SDLC template

A working six-stage SDLC loop driven by Claude Code and GitHub Actions, with no application code.
Copy this folder to a new empty repository, work through *Adapt it* below, and you have the loop.

```
intent → spec → plan + code → CI + AI review → deploy → monitor → intent
```

Each stage hands over by **committing an artefact**, not by moving a ticket. One slug —
`NNN-<short-name>` — ties the chain together:
`.sdlc/intent/<slug>.md` → `.sdlc/specs/<slug>.md` → `.sdlc/plans/<slug>.md` → PR → `.sdlc/lessons/`.

**The agent never passes a gate.** It writes artefacts and findings; every build, merge and release
needs a human action. The one automatic approval is the spec PR, and the pipeline grants it, not the agent.

## What is in here

Nothing here is tied to a language, framework or test runner. The only assumptions are `git`, `make`,
`bash`, `jq` and `awk` — plus `yq` for the flow check, which GitHub's Ubuntu runners preinstall.

| Path | What it does |
|---|---|
| `.sdlc/flow.yaml` | Declares the six stages, their triggers, artefacts and gates. The pipeline reads `stages.design.gate.approval` from it (`auto` \| `manual`); every other gate records who enforces it |
| `.sdlc/intent/_TEMPLATE.md`<br>`.sdlc/specs/_TEMPLATE.md`<br>`.sdlc/plans/_TEMPLATE.md` | The artefact shapes for stages 1, 2 and 3 |
| `.sdlc/REVIEW.md` | The three review passes the AI reviewer runs on every PR |
| `.sdlc/scripts/next_intent_number.sh` | Next slug number |
| `.sdlc/scripts/open_pr.sh` | Deterministic commit + PR, used by the workflows so the agent only ever writes files |
| `.sdlc/scripts/check_flow.sh` | Fails if `flow.yaml` names a missing workflow or template, or marks a gate `auto` that the pipeline cannot automate. Run by CI as its own step, independent of your test runner |
| `.sdlc/monitoring/bands.json` | Response tier per sigma: what the agent may do at 1σ, 2σ and 3σ |
| `.sdlc/monitoring/metrics.json` | Sample metric series — replace with a real source |
| `.sdlc/evals/` | Regression tests for the agent configuration itself, run on changes to `CLAUDE.md` and `.claude/**` |
| `.claude/settings.json` | Tool permissions plus the three hooks |
| `.claude/hooks/protect-paths.sh` | `SDLC_STAGE=build` freezes `.sdlc/intent/` and `.sdlc/specs/`; `SDLC_FIX_MODE=1` freezes the test directory |
| `.claude/hooks/production-gate.sh` | Blocks a production deploy without `RELEASE_APPROVAL` |
| `.claude/hooks/format-on-edit.sh` | Formats each edited file; a stub until you add your formatter. Never blocks |
| `.claude/hooks/_lib.sh` | Reads the hook payload using whichever of `jq`, `python3` or `node` is present |
| `.claude/skills/` | `write-intent`, `write-spec` (used by stages 1–2), `secure-api-review` (policy) |
| `.claude/agents/verifier.md` | Subagent that runs the checks and reports, after a build |
| `.github/workflows/` | `intent-to-spec`, `spec-to-build`, `claude`, `claude-review`, `ci`, `deploy`, `monitor`, `agent-evals`. The four that carry a gate are split in two: `_ci.yml`, `_claude-review.yml`, `_deploy.yml` and `_agent-evals.yml` hold the body and are versioned; the unprefixed file is a thin caller that owns only the triggers |
| `Makefile` | The one place the pipeline touches your stack. The workflows only ever call `make <target>` |
| `scripts/detect.sh` | Deterministic control-band detection in shell; the AI is only invoked on a breach |
| `scripts/deploy.sh`, `scripts/rollback.sh` | Simulated — point them at a real target |

## Use it

```bash
cp -R _template_repo ../my-project && cd ../my-project
git init && git add -A && git commit -m "SDLC scaffolding"
```

### One-time GitHub setup

1. **Install the Claude GitHub App** on the repo: `/install-github-app` in Claude Code, or <https://github.com/apps/claude>.
2. **Repository secrets** (Settings → Secrets and variables → Actions):
   - `CLAUDE_CODE_OAUTH_TOKEN` — from `claude setup-token`. For a team pipeline use an API key instead: the action input becomes `anthropic_api_key` and the CLI variable `ANTHROPIC_API_KEY`.
   - `SDLC_BOT_TOKEN` — a fine-grained PAT for this repo with *Contents*, *Pull requests* and *Issues* read/write. PRs opened with the default `GITHUB_TOKEN` **do not trigger other workflows**, so without this the spec and monitor PRs get no CI or review. Workflows fall back to `GITHUB_TOKEN`.
3. **Allow Actions to create and approve pull requests** (Settings → Actions → General), and **Allow auto-merge** (Settings → General). Both are needed for spec auto-approval.
4. **Create a `production` environment** with **required reviewers** — this is the release gate. Without reviewers, merges to `main` deploy straight through.
5. **Protect `main`**: require a PR, one code-owner approval, and the `ci / test` status check. Add `evals / suite` as a required check to gate agent-configuration changes. (A called workflow reports its job as `<caller job> / <called job>`, which is why the names are compound.)

Two gates live only in GitHub settings and appear in no file here: *allow Actions to create PRs*, and the `production` environment reviewers.

### Adapt it

The template ships with `make lint` and `make test` failing on purpose: a green check that ran
nothing is worse than a red one. Work down this list until CI is green.

1. **`Makefile`** — the only file the pipeline uses to reach your stack. The workflows call `install`, `lint`, `test`, `flow-check`, `evals` and `detect` by name; keep the names, replace the bodies. Leave everything below the "nothing below this line is stack-specific" marker alone. There is no toolchain setup in the workflows: GitHub's Ubuntu runners preinstall `python3`, `node`, `jq`, `awk` and `yq`, so `make install` provisions everything else — a virtualenv, a JDK, whatever the project needs.
2. **`.github/workflows/`** — nothing here is stack-specific. The four files with a `_`-prefixed twin (`ci`, `claude-review`, `deploy`, `agent-evals`) are thin callers: edit their triggers, not their bodies. To consume the standard by version instead of by copy, point each `uses:` at a tag and delete the local `_*.yml`:
   ```yaml
   jobs:
     ci:
       uses: kayshn/poc-sdlc-template/.github/workflows/_ci.yml@v1
       secrets: inherit
   ```
3. **`CLAUDE.md`** — fill in every `<...>`. The *Conventions* and *Things the agent gets wrong* sections are what actually steer the agent; be specific and name real symbols, not principles.
4. **`.sdlc/REVIEW.md`** — rewrite the *Security* bullet for this project's real risks.
5. **`.claude/skills/secure-api-review/SKILL.md`** — rewrite in terms of this project's own helpers and types, or delete it (and its references in `CLAUDE.md`, `.sdlc/REVIEW.md`, `claude-review.yml`, `flow.yaml` and `write-spec`). Add a skill per policy you want enforced at design time.
6. **`.claude/hooks/format-on-edit.sh`** — uncomment or add the formatter for your file types.
7. **`.claude/hooks/protect-paths.sh`** — change `tests/` to wherever this project keeps its tests.
8. **`.claude/agents/verifier.md`** — say how to exercise this project's behaviour directly, not just through the suite.
9. **`.sdlc/flow.yaml`** — set `stages.build.produces` to this project's real source and test directories.
10. **`scripts/deploy.sh` / `scripts/rollback.sh`** — point at a real target. Better still, expose deploy, status and rollback to the agent as MCP tools.
11. **`.sdlc/monitoring/metrics.json`** — replace the sample series with a real metrics source, and tune `bands.json`.
12. **`.sdlc/evals/cases/`** — one working, stack-free case ships (`intent-is-frozen-during-build`, which proves the hooks actually block). Copy `_EXAMPLE/` to add project-specific ones; folders starting with `_` are skipped.
13. **`.gitignore`** — add this project's build output and dependency directories.

Check your work with `make flow-check && make detect`, which work before any of the above is done.

### Drive one change round the loop

1. **Plan.** Ask the agent: *"Use the write-intent skill: \<your idea\>."* It writes `.sdlc/intent/<slug>.md`. Open a PR; `claude-review` comments; a code owner merges.
2. **Design (automatic).** The merge fires `intent-to-spec.yml`. The agent writes `.sdlc/specs/<slug>.md` with areas of concern flagged, and a PR opens. The pipeline sets `Status: approved (auto)` and auto-merges once `test` is green.
3. **Build.** The merge fires `spec-to-build.yml`, which opens a *Build: \<slug\>* issue quoting the concerns. **Nothing is built until a person comments `@claude` there** — that is where you reject a spec. `claude.yml` commits the plan, implements it, runs lint and tests, pushes a `claude/issue-N-*` branch and posts a *Create PR* link.
4. **Test and review.** `ci.yml` runs lint and tests (and triages its own failure). `claude-review.yml` posts findings and a `REVIEW-TALLY` line — comments only, never an approval. Reply `@claude fix this` to iterate. A code owner approves and merges.
5. **Deploy.** A green CI run on `main` starts `deploy.yml`. The agent drafts release notes into the job summary; the production environment's reviewers gate the deploy.
6. **Maintain.** `monitor.yml` runs `scripts/detect.sh` on a schedule. On a 2σ breach the agent diagnoses read-only and opens a monitor intent PR — back to step 1, with nobody in the invocation path. At 3σ the pre-approved rollback runbook also runs. Try it with **Run workflow → inject `0.052`** (2σ) or `0.2` (3σ).

To require a product owner on every spec instead, set `stages.design.gate.approval: manual` in `.sdlc/flow.yaml`.

Nothing above needs to run on your machine: every workflow runs on a GitHub-hosted runner. Claude Code
locally is a convenience. Locally the same hooks apply — `SDLC_FIX_MODE=1 claude` freezes `tests/`,
`SDLC_STAGE=build claude` freezes `.sdlc/intent/` and `.sdlc/specs/`.
