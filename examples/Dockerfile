# Lightweight, multi-stage image to keep the final image small
FROM python:3.11-slim AS base

# uv binary copied from its official image — no pip bootstrap needed
COPY --from=ghcr.io/astral-sh/uv:latest /uv /uvx /usr/local/bin/

WORKDIR /app

# Minimal system dependencies, only if actually needed (e.g. compiling C libs)
# RUN apt-get update && apt-get install -y --no-install-recommends gcc && rm -rf /var/lib/apt/lists/*

COPY pyproject.toml uv.lock ./
RUN uv sync --frozen --no-dev

COPY src/ ./src/

# Logs mounted as a volume from docker-compose, not written into the image
ENV LOG_LEVEL=INFO
ENV PYTHONUNBUFFERED=1

CMD ["uv", "run", "python", "-m", "src"]
