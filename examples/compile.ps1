# Compile main.tex via the shared cours-latex Docker image (build once from
# claude-code-config/docker/latex/ - see that folder's README). Self
# -contained: no dependency on claude-code-config's path at runtime, only
# on the cours-latex:latest image tag already built locally.

$Image = "cours-latex:latest"

$null = docker image inspect $Image 2>$null
if ($LASTEXITCODE -ne 0) {
    Write-Error "Image '$Image' not found locally. Build it once from claude-code-config/docker/latex/:`n  docker build -t $Image <path-to-claude-code-config>/docker/latex/"
    exit 1
}

docker run --rm -v "${PWD}:/workspace" -w /workspace $Image `
    latexmk -lualatex -shell-escape -interaction=nonstopmode -halt-on-error main.tex

exit $LASTEXITCODE
