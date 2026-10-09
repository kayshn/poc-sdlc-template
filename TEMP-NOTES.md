<< MUST BE IGNORED BY AGENTS >>

## QUESTIONS
- Evaluate using Copilot instead of Claude?
- Evaluate AWS SDLC?
- Improve evals and measuring agent performance?
- Measure value from using DLC?
- Have a check in pipeline to fail any build that uses old DLC version?

## TODO
- Update spec step to create and update C4 diagrams if necessary
- Verify the monitor stage

## DLC Test Scenarios
1. Scenario 1 — template ships an engineering guardrail, consumer pulls it in. √
2. Scenario 2 - template updates the intent template, and Consumer repos update to receive it.
3. Template modifies a gate in the workflow and Consumer repos update to receive it.
4. Template modifies a pipeline (GH Actions) step and Consumer repos update to receive it.
5. Consumer implements a new feature (idea) and intent > spec > .. cycle kicks in


## File System Structure
---
Template repo only:

[S] Standard body — the _*.yml workflow bodies. Live only in the template, consumed remotely via uses: …@tag. Must not exist in a consumer: workflow_call never self-fires, so a copy there is inert and check_template.sh fails on it.

[T] Template-only — the template repo's own upkeep: TODO.md, TEMP-NOTES.md, make_manifest.sh. Removed from a repo created from the template.

---
Repeatedly provided by Template at every tag update:

[I] Invariant — named in .sdlc/invariant.txt, hashed in MANIFEST.sha256, redelivered at every tag by make sdlc-update. Editing it locally fails template-check. 17 files.

[G] Generated — bookkeeping written by tooling: MANIFEST.sha256, TEMPLATE_VERSION. Arrives from the tag, not yours to edit, not hashed itself.

--- 
Initially provided by Template, then modified by Consumer:

[H] Hybrid — you own the file; the standard owns a contract inside it (a line, a key, a heading), checked by grep rather than by hash. 13 files.

[V] Variant — seeded once at repo creation, yours forever, never redelivered. A consumer created before a [V] file existed never receives it.

---
Created by Consumer, never provided by Template:

[L] Loop output — artefacts the six stages write per lap: .sdlc/intent/<slug>.md, specs/<slug>.md, plans/<slug>.md. Yours, but authored by the loop rather than by hand. 9 files in the consumer.

[A] Application — the actual product. In the consumer: src/, tests/, pyproject.toml, the two requirements files. 5 files.

--- 

poc-sdlc-consumer-app/
├── .claude/
│   ├── agents/verifier.md                                  [V]
│   ├── hooks/_lib.sh                                       [I]
│   ├── hooks/production-gate.sh                            [I]
│   ├── hooks/protect-paths.sh                              [I]
│   ├── hooks/format-on-edit.sh                             [V] ? why V?
│   ├── settings.json                                       [H]
│   └── skills/{secure-api-review,write-intent,write-spec}  [V] ? why V?
├── .github/workflows/          ← 9 thin callers, no _*.yml leftovers: correct
│   ├── agent-evals.yml  ci.yml  claude-review.yml          [H] ? why H
│   ├── claude.yml  deploy.yml  intent-to-spec.yml          [H] ? why H
│   └── monitor.yml  sdlc-update.yml  spec-to-build.yml     [H] ? why H
├── .sdlc/
│   ├── TEMPLATE_VERSION                                    [G]  v2.2.0, 2026-10-09
│   ├── MANIFEST.sha256                                     [G]
│   ├── invariant.txt                                       [I]
│   ├── standards/engineering-guardrails.md                 [I]  G1–G5 here
│   ├── scripts/_sdlc_lib.sh  check_flow.sh                 [I]
│   ├── scripts/check_template.sh  next_intent_number.sh    [I]
│   ├── scripts/open_pr.sh  sdlc_update.sh                  [I]
│   ├── scripts/trust_workspace.sh                          [I]
│   ├── evals/run_evals.sh                                  [I]
│   ├── evals/cases/intent-is-frozen-during-build/          [I]  check.sh, env, prompt.md
│   ├── evals/cases/_EXAMPLE/                               [V]  5 files
│   ├── flow.yaml                                           [H]
│   ├── REVIEW.md                                           [H]
│   ├── protected-paths.txt                                 [H]
│   ├── intent/_TEMPLATE.md  specs/_TEMPLATE.md             [V]
│   ├── plans/_TEMPLATE.md                                  [V]
│   ├── monitoring/bands.json  monitoring/metrics.json      [V]
│   ├── lessons/README.md                                   [V]
│   ├── intent/000-expiring-links.md                        [L]
│   ├── intent/001-monitor-ci-test-failure-rate-…md         [L]
│   ├── intent/002-link-follow-count.md                     [L]
│   ├── specs/000…md  specs/001…md  specs/002…md            [L]
│   └── plans/000…md  plans/001…md  plans/002…md            [L]
├── scripts/deploy.sh  detect.sh  rollback.sh               [V]
├── CLAUDE.md                                               [H]
├── Makefile                                                [H]
├── SDLC-GUIDE.md                                           [I]
├── README.md                                               [V]
├── pyproject.toml                                          [A]
├── requirements.txt  requirements-dev.txt                  [A]
├── src/app/main.py                                         [A]
└── tests/test_main.py                                      [A]