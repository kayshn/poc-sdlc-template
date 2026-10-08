# The workflows call these targets by name: install, lint, test, flow-check, evals, detect.
# Keep the names; replace the bodies with whatever this project's stack needs.
# `lint` and `test` deliberately fail until you wire them up — a green check that ran nothing is
# worse than a red one.
.PHONY: install lint test format run flow-check evals detect

install:
	@echo "TODO: install dependencies (npm ci / mvn verify -DskipTests / go mod download / ...)"

lint:
	@echo "TODO: wire up the linter for this project" && exit 1

test:
	@echo "TODO: wire up the test suite for this project" && exit 1

format:
	@echo "TODO: wire up the formatter for this project"

run:
	@echo "TODO: start the application"

# Nothing below this line is stack-specific — leave it alone.

flow-check:
	./.sdlc/scripts/check_flow.sh

evals:
	./.sdlc/evals/run_evals.sh

detect:
	./scripts/detect.sh --bands .sdlc/monitoring/bands.json --metrics .sdlc/monitoring/metrics.json
