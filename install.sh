#!/usr/bin/env bash
# install.sh - Install one or more Claude Code skills from this repo into ~/.claude/skills/
#
# Usage:
#   ./install.sh                    # interactive: pick from a menu
#   ./install.sh <skill-name>       # install one skill by name
#   ./install.sh --all              # install every skill
#   ./install.sh --copy <skill>     # copy instead of symlink (default is symlink)
#
# Examples:
#   ./install.sh mac-cleanup
#   ./install.sh --all

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SKILLS_SRC="$REPO_ROOT/skills"
SKILLS_DST="$HOME/.claude/skills"

MODE="symlink"

print_usage() {
    sed -n '2,11p' "${BASH_SOURCE[0]}" | sed 's/^# \{0,1\}//'
}

list_skills() {
    find "$SKILLS_SRC" -mindepth 1 -maxdepth 1 -type d -exec basename {} \; | sort
}

install_one() {
    local skill="$1"
    local src="$SKILLS_SRC/$skill"
    local dst="$SKILLS_DST/$skill"

    if [[ ! -d "$src" ]]; then
        echo "ERROR: skill '$skill' not found in $SKILLS_SRC" >&2
        return 1
    fi

    mkdir -p "$SKILLS_DST"

    if [[ -e "$dst" || -L "$dst" ]]; then
        echo "WARNING: $dst already exists. Skipping. (Remove it first to re-install.)"
        return 0
    fi

    if [[ "$MODE" == "copy" ]]; then
        cp -R "$src" "$dst"
        echo "Copied:    $skill -> $dst"
    else
        ln -s "$src" "$dst"
        echo "Linked:    $skill -> $dst"
    fi
}

# --- Parse args ---
SKILLS_TO_INSTALL=()
INSTALL_ALL=false

while [[ $# -gt 0 ]]; do
    case "$1" in
        -h|--help)
            print_usage
            exit 0
            ;;
        --all)
            INSTALL_ALL=true
            shift
            ;;
        --copy)
            MODE="copy"
            shift
            ;;
        --symlink)
            MODE="symlink"
            shift
            ;;
        -*)
            echo "Unknown flag: $1" >&2
            print_usage
            exit 1
            ;;
        *)
            SKILLS_TO_INSTALL+=("$1")
            shift
            ;;
    esac
done

# --- Resolve skill list ---
if $INSTALL_ALL; then
    while IFS= read -r s; do SKILLS_TO_INSTALL+=("$s"); done < <(list_skills)
elif [[ ${#SKILLS_TO_INSTALL[@]} -eq 0 ]]; then
    echo "Available skills:"
    list_skills | sed 's/^/  - /'
    echo ""
    read -r -p "Skill name to install (or 'all'): " choice
    if [[ "$choice" == "all" ]]; then
        while IFS= read -r s; do SKILLS_TO_INSTALL+=("$s"); done < <(list_skills)
    else
        SKILLS_TO_INSTALL+=("$choice")
    fi
fi

# --- Install ---
echo ""
echo "Mode: $MODE"
echo "Target: $SKILLS_DST"
echo ""

for skill in "${SKILLS_TO_INSTALL[@]}"; do
    install_one "$skill"
done

echo ""
echo "Done. Restart Claude Code or start a new session to discover the new skill(s)."
