# Data engineering Python — validation, pipelines, reproducibility

Applies to Python data pipelines using Polars, pandas, or both.
General Python rules (typing, uv, OOP) are in `rules/python/`.

## Data validation

- **Validate early, validate often**: place validation checks at every boundary where data enters the system — after file load, after API call, after each major transformation step. Never defer to the end of the pipeline.
- Use **Pandera** for schema validation in pure Python/pandas/Polars projects (type hints, unit-test-style validations, lightweight). Reserve Great Expectations for heterogeneous enterprise pipelines (Spark/SQL). Pandera integrates with both pandas and Polars DataFrames.
- Enable `strict=True` on the schema in production — any unexpected column triggers an error immediately, catching upstream schema changes before they silently corrupt outputs.
- Define explicit types at read time rather than relying on inference; prefer explicitly nullable types to avoid silent missing-value behavior.
- Validate primary key uniqueness, foreign key validity, and join cardinality — silent row explosions from bad joins are among the most expensive bugs to find post-deploy.

## Storage and intermediate formats

- Store source-of-truth data in **Parquet** with a stable schema — preserves types across reads. Never use CSV for intermediate pipeline data: no type encoding, no schema, ambiguous nulls.
- For **point-in-time correctness**: any feature or aggregate must only use information that was genuinely available at time T in the real world. Violating this causes data leakage that only shows up as unexplained model overperformance in training and underperformance in production.

## Pipeline structure

- Clearly separate **Extract / Transform / Load** once the script exceeds ~50 lines — never one monolithic script.
- Transformations must be deterministic and stateless where possible — they are far easier to test, replay, and debug.
- Avoid chain indexing and row-wise operations for core business logic in pandas (performance + silent copy bugs). Use vectorized operations.

## Observability on each run

Track and log (structured JSONL per `rules/common/logging.md`) after each pipeline step:
- Execution time
- Row count in / row count out
- Null count on key columns
- Output size

Add "stop-the-line" checks before publishing outputs (before writing to warehouse, before API response) — errors must include actionable context (which partition, which file, which check failed).

## Reproducibility

- Deterministic transforms + pinned deps (`uv.lock`) + versioned input data = reproducible runs. Any deviation from this triangle is a debugging liability.
- Log enough context on every run (input paths, row counts, schema hash) to be able to diagnose a silent data drift without re-running the pipeline from scratch.
