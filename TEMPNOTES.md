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
1. Template updates an Engineering Guardrail or Satndard and Consumer repos update to receive it.
2. Template modifies a gate in the workflow and Consumer repos update to receive it.
3. Template modifies a pipeline (GH Actions) step and Consumer repos update to receive it.
4. Consumer implements a new feature (idea) and intent > spec > .. cycle kicks in
