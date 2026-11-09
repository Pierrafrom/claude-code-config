#!/usr/bin/env bash
# PostToolUse hook (Write|Edit): in projects that opt in with
# CLAUDE_NO_EM_DASH=1 (set in the project's .claude/settings.json "env"),
# report any em dash in the written text file back to Claude (exit 2).
# Opt-in because the rule is project-specific (graded academic papers),
# not a global style rule.
set -uo pipefail

[ "${CLAUDE_NO_EM_DASH:-0}" = "1" ] || exit 0

payload="$(cat)"
file_path="$(printf '%s' "$payload" | sed -n 's/.*"file_path"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' | head -n1)"
file_path="${file_path//\\\\//}"

case "$file_path" in
  *.tex|*.md|*.bib) ;;
  *) exit 0 ;;
esac
[ -f "$file_path" ] || exit 0

em_dash=$'\xe2\x80\x94'
hits="$(grep -nF -- "$em_dash" "$file_path" | head -n 5)"
latex_hits=""
case "$file_path" in
  *.tex) latex_hits="$(grep -nE '(^|[^-])---([^-]|$)' "$file_path" | grep -v '^[0-9]*:[[:space:]]*%' | head -n 5)" ;;
esac

if [ -n "$hits$latex_hits" ]; then
  {
    echo "Em dash found in $file_path (forbidden in this project). Replace with a period, comma, colon or parentheses:"
    [ -n "$hits" ] && echo "$hits"
    [ -n "$latex_hits" ] && echo "$latex_hits"
  } >&2
  exit 2
fi
exit 0
