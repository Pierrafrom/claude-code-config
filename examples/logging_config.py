"""JSONL logging configuration — copy into src/<package>/logging_config.py

Usage in application code:

    from logging_config import get_logger
    logger = get_logger(__name__)
    logger.error("missing column", extra={"ctx": {"file": "sales.csv", "col": "region"}})

Output format (one JSON line per event):
    {"ts": "...", "level": "ERROR", "module": "...", "msg": "...", "ctx": {...}}
"""

import json
import logging
import os
import sys
from datetime import UTC, datetime
from pathlib import Path

LOG_DIR = Path("logs")
LOG_LEVEL = os.environ.get("LOG_LEVEL", "INFO")


class JsonlFormatter(logging.Formatter):
    """Serializes each log record into one JSON line (fixed fields, see rules/common/logging.md)."""

    def format(self, record: logging.LogRecord) -> str:
        payload = {
            "ts": datetime.fromtimestamp(record.created, tz=UTC).isoformat(),
            "level": record.levelname,
            "module": record.name,
            "msg": record.getMessage(),
            "ctx": getattr(record, "ctx", {}),
        }
        return json.dumps(payload, ensure_ascii=False, separators=(",", ":"))


def get_logger(name: str) -> logging.Logger:
    """Returns a configured logger: JSONL file + stdout, level via LOG_LEVEL."""
    logger = logging.getLogger(name)
    if logger.handlers:
        return logger  # already configured, avoids duplicate handlers

    logger.setLevel(LOG_LEVEL)

    LOG_DIR.mkdir(exist_ok=True)
    file_handler = logging.FileHandler(LOG_DIR / "app.jsonl", encoding="utf-8")
    file_handler.setFormatter(JsonlFormatter())
    logger.addHandler(file_handler)

    stream_handler = logging.StreamHandler(sys.stdout)
    stream_handler.setFormatter(JsonlFormatter())
    logger.addHandler(stream_handler)

    return logger
