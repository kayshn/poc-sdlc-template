# Your project's targets. The workflows call install, lint, test and format by name, and the agent
# calls format-file and verify — keep the names, replace the bodies with whatever this stack needs.
# `lint` and `test` deliberately fail until you wire them up: a green check that ran nothing is
# worse than a red one.
#
# Everything the SDLC loop itself needs arrives in .sdlc/upstream/sdlc.mk, included at the bottom.
.PHONY: install lint test format format-file verify run manifest

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

# Template repo only, so not in sdlc.mk: re-hashes the received layer after changing it.
manifest:
	./tools/make_manifest.sh

include .sdlc/upstream/sdlc.mk
