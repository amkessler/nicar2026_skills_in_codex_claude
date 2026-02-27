#!/bin/bash
# Wrapper script that sets CODEX_HOME to this repo's .codex/ directory,
# so Codex picks up the project-local skills without any manual env setup.
# Usage: ./codex.sh [any codex arguments]
CODEX_HOME="$(dirname "$0")/.codex" codex "$@"
