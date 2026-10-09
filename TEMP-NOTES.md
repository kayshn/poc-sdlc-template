<< MUST BE IGNORED BY AGENTS >>

## TODO - K1
- Evaluate using Copilot instead of Claude
- Evaluate AWS SDLC
- Improve evals and measuring agent performance
- Measure value from using DLC
- Clarify how versioning works in template and consumer works
- Add some engineering guardrails
- Update spec step to create and update C4 diagrams if necessary
- Test the monitor stage
- Have a check in pipeline to fail any build that uses old DLC version

## DLC Test Scenarios
1. Scenario 1 — template ships an engineering guardrail, consumer pulls it in. √
2. Scenario 2 - template updates the intent template, and Consumer repos update to receive it.
3. Template modifies a gate in the workflow and Consumer repos update to receive it.
4. Template modifies a pipeline (GH Actions) step and Consumer repos update to receive it.
5. Consumer implements a new feature (idea) and intent > spec > .. cycle kicks in
