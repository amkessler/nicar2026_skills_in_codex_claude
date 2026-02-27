#!/bin/bash
# Wrapper script that sets CODEX_HOME to this repo's .codex/ directory,
# so Codex picks up the project-local skills without any manual env setup.
# Auth and other global config are symlinked from ~/.codex/ automatically,
# so your existing login and preferences carry over.
# Usage: ./codex.sh [any codex arguments]

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
LOCAL_CODEX="$SCRIPT_DIR/.codex"
GLOBAL_CODEX="$HOME/.codex"

# Symlink auth, config, and other global files into the local CODEX_HOME
# so the session uses your existing login. Skips the skills/ directory
# (that's what we're overriding) and anything already present locally.
if [ -d "$GLOBAL_CODEX" ]; then
    for item in "$GLOBAL_CODEX"/*; do
        [ -e "$item" ] || continue
        name="$(basename "$item")"
        [ "$name" = "skills" ] && continue
        if [ ! -e "$LOCAL_CODEX/$name" ]; then
            ln -sf "$item" "$LOCAL_CODEX/$name"
        fi
    done
fi

CODEX_HOME="$LOCAL_CODEX" codex "$@"
