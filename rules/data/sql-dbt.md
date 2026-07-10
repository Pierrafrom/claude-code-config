# SQL & dbt — style, architecture, workflow

## SQL style

- 4-space indentation inside every CTE and for all multi-line clauses (column lists, JOINs, GROUP BY).
- One blank line above and below each main query block; comment CTEs with `--` (or Jinja `{# #}` for compile-time-only comments in dbt).
- Always end with a `SELECT *` from the last named CTE (conventionally `final`) — intermediate CTEs are explicit named steps, not abbreviated shortcuts.
- Readability over line count — line breaks are free, human brain time is not.
- `!=` not `<>`. `UNION ALL` not `UNION` — a plain `UNION` can silently hide upstream integrity problems better fixed at the source.
- `LOWER(column) LIKE '%match%'` not `column ILIKE '%Match%'` — avoids engine-specific case surprises.
- Never `USING` in JOINs (ambiguous across engines) — always explicit `ON`.
- Use the engine's canonical types (`NUMBER` not `DECIMAL`/`INTEGER`, `VARCHAR` not `STRING`/`TEXT`).
- Prefer `CASE field WHEN 1 THEN …` over `CASE WHEN field = 1 THEN …` when testing a single column.
- Never store monetary amounts as float — use integer cents (`BIGINT`) to avoid floating-point rounding errors.

## dbt architecture

**Layering and references:**
- Every model references others via `ref()`, never a hardcoded table name — this lets dbt infer the DAG and build in the right order.
- Staging models are the only layer that references `source()` — downstream layers (intermediate, marts) only use `ref()`. A model must not mix `source()` and `ref()` in the same file.
- Staging layer is rename/recast only: standardize column names (all timestamps as `<event>_at` in UTC, prices as decimal amounts), recast types — no aggregations, no filters, no business logic.
- Table prefixes: `stg_` for staging, `fct_` for facts, `dim_` for dimensions, `int_` for intermediate.
- Full naming convention: `stg_<source>__<entity>` for staging (double underscore separates source from entity), `int_<description>` for intermediate, `fct_<event>` / `dim_<entity>` for marts.

## Project structure

See `rules/common/project-architectures.md` for the governing rule (a
pattern to converge toward, not a mandate). Source:
docs.getdbt.com/best-practices/how-we-structure — dbt's own documented
convention for the three-layer split.

```
my-dbt-project/
├── models/
│   ├── staging/                   # Layer 1 — clean raw sources
│   │   ├── salesforce/
│   │   │   ├── _salesforce__sources.yml   # Source definition
│   │   │   ├── _salesforce__models.yml    # Model documentation
│   │   │   ├── stg_salesforce__contacts.sql
│   │   │   └── stg_salesforce__accounts.sql
│   │   └── stripe/
│   │       ├── _stripe__sources.yml
│   │       ├── stg_stripe__payments.sql
│   │       └── stg_stripe__subscriptions.sql
│   │
│   ├── intermediate/              # Layer 2 — transforms between staging and marts
│   │   ├── finance/int_payments_pivoted.sql
│   │   └── marketing/int_customer_lifetime_value.sql
│   │
│   └── marts/                     # Layer 3 — consumable by analysts
│       ├── finance/
│       │   ├── _finance__models.yml
│       │   ├── fct_orders.sql
│       │   └── dim_customers.sql
│       └── marketing/
│           ├── fct_campaigns.sql
│           └── dim_segments.sql
│
├── macros/                        # Reusable Jinja macros
│   ├── generate_schema_name.sql
│   └── cents_to_dollars.sql
│
├── tests/                         # Custom tests, beyond the generic built-ins
│   └── assert_positive_revenue.sql
│
├── seeds/                         # Static CSVs versioned in Git
│   └── country_codes.csv
│
├── analyses/                      # Ad-hoc queries, not models
├── snapshots/                     # SCD Type 2 via dbt snapshot
│
├── dbt_project.yml                # Main config
├── profiles.yml                   # Connections — never committed (.gitignore)
├── packages.yml                   # dbt dependencies (dbt-utils, dbt-audit-helper)
└── .sqlfluff                      # SQLFluff config
```

**Tests and quality:**
- Every model must have at minimum a primary key tested for `unique` and `not_null`.
- Run `dbt-project-evaluator` (or equivalent) to detect structural violations automatically: direct source joins in non-staging models, undocumented models, duplicate sources.
- Lint SQL with **SQLFluff** (`--templater dbt`); format with `sqlfmt` or `sqlfluff fix` — one detects style issues, the other auto-corrects formatting.

**Materialization choices:**
- `view`: simple logic that must always be fresh.
- `table`: fast queries on large volumes with complex logic.
- `incremental`: frequent updates where rebuilding the full table is too slow.
- `ephemeral`: CTE-like, no physical storage, complexity reduction only.

**DRY in SQL:** if a logic block repeats, extract it as a reusable CTE, a Jinja macro, or a separate model.

## Workflow

- All dbt projects versioned in Git; feature/fix branches with mandatory code review before merge to production.
- Default target: `dev`; `prod` only in automated deployment — never run production builds manually from a developer machine.
- Always keep a raw copy of source data in the warehouse — enables re-running models without re-ingesting, and faster gap identification.
