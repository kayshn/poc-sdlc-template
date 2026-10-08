#!/usr/bin/env bash
# PreToolUse(Edit|Write): block edits to approved artefacts, and to tests while fixing a bug.
source "$(dirname "$0")/_lib.sh"
payload=$(cat)
path=$(field "$payload" tool_input.file_path)
rel="${path#"$CLAUDE_PROJECT_DIR"/}"

# TEMPLATE: change `tests/` to wherever this project keeps its tests.
if [[ "${SDLC_FIX_MODE:-}" == "1" && "$rel" == tests/* ]]; then
  echo "Blocked: SDLC_FIX_MODE=1, so tests are frozen. Fix the code, not the test." >&2
  exit 2
fi
if [[ "${SDLC_STAGE:-}" == "build" && ( "$rel" == .sdlc/intent/* || "$rel" == .sdlc/specs/* ) ]]; then
  echo "Blocked: intent and approved specs are read-only during build. Raise a question in the PR instead." >&2
  exit 2
fi
exit 0
