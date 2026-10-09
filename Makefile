# The workflows call these targets by name: install, lint, test, flow-check, template-check,
# evals, detect. Keep the names; replace the bodies with whatever this project's stack needs.
# `lint` and `test` deliberately fail until you wire them up — a green check that ran nothing is
# worse than a red one.
.PHONY: install lint test format format-file verify run flow-check template-check evals detect manifest sdlc-update

install:
	@echo "TODO: install dependencies (npm ci / mvn verify -DskipTests / go mod download / ...)"

lint:
	@echo "TODO: wire up the linter for this project" && exit 1

test:
	@echo "TODO: wire up the test suite for this project" && exit 1

format:
	@echo "TODO: wire up the formatter for this project"

# One file, called by the format-on-edit hook after every agent edit. Keep it fast and quiet; its
# output and exit status are discarded so that a formatter can never interrupt the agent.
format-file:
	@echo "TODO: format just $(FILE)"

# Exercise the app directly, not through the test suite: call the endpoint, drive the CLI, run the
# job against a fixture. The verifier agent runs this before a session reports done.
verify:
	@echo "TODO: wire up a direct exercise of this project's behaviour"

run:
	@echo "TODO: start the application"

# Nothing below this line is stack-specific — leave it alone.

flow-check:
	./.sdlc/scripts/check_flow.sh

template-check:
	./.sdlc/scripts/check_template.sh

# Upgrade the invariant layer. Not part of `install`: CI verifies, humans upgrade.
sdlc-update:
	./.sdlc/scripts/sdlc_update.sh

# Template repo only: re-hash the invariant layer after changing it.
manifest:
	./.sdlc/scripts/make_manifest.sh

evals:
	./.sdlc/evals/run_evals.sh

detect:
	./scripts/detect.sh --bands .sdlc/monitoring/bands.json --metrics .sdlc/monitoring/metrics.json
