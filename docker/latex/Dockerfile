# Base: hub.docker.com/r/texlive/texlive — Island of TeX, "full" scheme,
# includes latexmk, LuaLaTeX, TikZ/pgfplots, tcolorbox, glossaries, KOMA-Script.
# Extends the official image rather than installing TeX Live from scratch —
# see rules/common/config-standards.md. Re-check the tag on the Docker Hub
# page above before rebuilding after a long gap; `latest-full` floats to the
# newest TeX Live release on purpose (see docker/latex/README.md).
FROM texlive/texlive:latest-full

# Pygments: required by the `minted` LaTeX package for syntax highlighting
# (already bundled by the base image, pinned here explicitly so a future
# `latest-full` rebuild can't silently drop it).
# poppler-utils: pdftotext/pdfimages/pdftoppm, used by the cours-latex skill
# to extract text and images from a source course PDF before writing LaTeX.
# fonts-firacode: code font loaded via fontspec in examples/latex-preamble.sty
# (LuaLaTeX). No separate text/math font package is needed: the "full" TeX
# Live scheme already ships the complete Libertinus family (Serif/Sans/
# Mono/Math) used for body text and unicode-math — verified via `fc-list`,
# see docker/latex/README.md.
RUN apt-get update && apt-get install -y --no-install-recommends \
      python3-pygments \
      poppler-utils \
      fonts-firacode \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /workspace
