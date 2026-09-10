#!/usr/bin/env bash
# Compile main.tex via the shared cours-latex Docker image (build once from
# claude-code-config/docker/latex/ — see that folder's README). Self
# -contained: no dependency on claude-code-config's path at runtime, only
# on the cours-latex:latest image tag already built locally.
set -euo pipefail

IMAGE="cours-latex:latest"

if ! docker image inspect "$IMAGE" >/dev/null 2>&1; then
  echo "Image '$IMAGE' not found locally." >&2
  echo "Build it once from claude-code-config/docker/latex/:" >&2
  echo "  docker build -t $IMAGE <path-to-claude-code-config>/docker/latex/" >&2
  exit 1
fi

docker run --rm -v "$(pwd):/workspace" -w /workspace "$IMAGE" \
  latexmk -lualatex -shell-escape -interaction=nonstopmode -halt-on-error main.tex
