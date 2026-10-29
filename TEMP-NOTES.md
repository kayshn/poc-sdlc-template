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
