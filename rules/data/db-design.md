# Database design — OLTP, OLAP/Kimball, Data Vault

## Routing — apply the right model for the workload

| Situation | Apply |
|---|---|
| Real-time transactional system (CRUD, concurrent writes) | OLTP section — target 3NF |
| Analytical pipeline / BI / reporting (dbt, Snowflake, Power BI) | Kimball section — star schema by default |
| 10+ heterogeneous source systems, strong audit requirements | Data Vault as integration layer + Kimball as presentation layer |

Never force one strategy onto both workloads. Applying 3NF to a warehouse or a star schema to a transactional system are the two canonical design mistakes.

## OLTP (transactional)

**Normalization:**
- Target 3NF by default; apply BCNF only when a concrete dependency conflict is observed, not preemptively.
- 1NF: atomic values only — no lists, nested structures, or repeating groups in a column.
- 2NF: every non-key attribute depends on the whole primary key (matters for composite keys).
- 3NF: no transitive dependencies between non-key attributes. Classic violation: a `customer` table with both `region_id` (FK) and `region_name` (attribute that depends on `region_id`, not on `customer_id`).
- JSON or nested fields may be valid in a staging/document layer but violate 1NF in a normalized OLTP schema — do not use JSON as a substitute for proper relational modeling.

**Constraints — always explicit:**
- `NOT NULL` by default unless there is a clear business reason for nullable.
- `UNIQUE` on natural keys.
- `CHECK` for domain rules (e.g. `age >= 0`, `status IN ('active', 'inactive')`).
- `FOREIGN KEY` with an explicit `ON DELETE` / `ON UPDATE` policy — never left to the engine default.

**Primary key choice:**
- Natural key only if it is genuinely stable and immutable (rare in practice — email, phone number, and external IDs all change).
- Otherwise: auto-incremented integer or UUID as surrogate key. Never use a "nearly stable" attribute as a PK.

**ACID is non-negotiable:**
- The transactional database is the system of record — transactions commit fully or have zero effect. Any design that works around this (e.g. application-level partial commit) is a reliability regression.

**Monetary amounts:**
- Always store in integer cents (`BIGINT`) — never `FLOAT` or `DOUBLE`, which introduce rounding errors in arithmetic.

## OLAP / Data Warehouse — Kimball dimensional modeling

**The four-step Kimball process (always in this order):**
1. Identify the business process (the core activity generating value — sales, subscriptions, sessions).
2. Declare the grain (the lowest level of detail in the fact table — one row = what exactly?).
3. Identify the dimensions.
4. Identify the facts/measures.

**Star vs snowflake:**
- **Star schema** (denormalized dimensions directly joined to the fact table) is the default for modern analytical warehouses — storage is cheap, join simplicity directly impacts analyst productivity.
- **Snowflake schema** (normalized sub-dimensions) reduces redundancy but multiplies joins — reserve for dimensions exceeding ~100 columns or with explicit storage constraints. Never snowflake by default.

**Keys:**
- Use **surrogate keys** (auto-generated integers) as dimension PKs — they are stable, performant, and handle SCD Type 2 correctly. Natural/business keys are stored as attributes, not as PKs.
- Suffix surrogate keys with `_key` to distinguish them from natural keys (e.g. `customer_key` vs `customer_id`).
- Never join on raw dates — always join through `dim_date`.
- Conform shared dimensions (`dim_date`, `dim_customer`, `dim_product`) across all fact tables — same keys, same attributes — to enable cross-process analysis.

**Slowly Changing Dimensions (SCD):**
- Type 1: overwrite, no history — for non-critical attributes where only current value matters.
- Type 2: new row with effective dates (`valid_from` / `valid_to` + `is_current` flag) — full history, use when temporal accuracy is required for analytics.
- Type 3: add columns for previous values — limited history, use rarely.
- **Default: Type 2** for any dimension attribute that affects historical analysis correctness.

**Fact tables:**
- Determine grain before modeling anything else — it is the most structural decision.
- Fact rows contain foreign keys to all relevant dimensions + additive measures (amounts, counts, durations).
- Measures that cannot be additively aggregated (e.g. ratios, percentages) belong in the BI layer, not the fact table.

## Data Vault 2.0

Use when: 10+ heterogeneous source systems, significant audit pressure, or frequent schema changes that Kimball alone cannot absorb. For small teams with few sources, Kimball delivers faster and is easier to explain to stakeholders.

**Three structures:**
- **Hubs**: business keys (the unique identities of core business concepts — customer ID, order ID). Hubs never change.
- **Links**: relationships between business concepts (an order contains products → a link between the Order hub and the Product hub).
- **Satellites**: descriptive attributes and context, with full change history. One satellite per source system per hub/link — never mix data from two sources in one satellite.

**Key rules:**
- Use **hash keys** (SHA-1/SHA-256 of the business key) as PKs — computed in parallel without coordination, enabling horizontal scale.
- Use **hash_diff** (hash of all satellite attributes) to detect changes — if the new hash_diff matches the latest row, skip the insert (idempotent loads).
- Hubs and satellites are **insert-only** (append-only) — never overwrite an existing row, preserving complete auditability.

**Layering with Kimball:**
Data Vault and Kimball are not mutually exclusive — use Data Vault for ingestion and history preservation (Silver in Medallion), Kimball star schemas for consumption (Gold). The vault absorbs schema change; the star schema serves fast queries.

**Medallion architecture (modern standard):**
- Bronze = raw data, untouched.
- Silver = Data Vault layer — cleansed, deduplicated, full history.
- Gold = Kimball star schemas — ready for BI tools.

## Indexing and performance

- **OLTP**: index join columns and frequent filter columns (especially foreign keys). Keep indexes narrow.
- **OLAP**: partitioning and clustering on habitual filter columns (date, region) matter more than multiple indexes. For queries that always retrieve "the latest version," store the most recent record first (descending index on the timestamp column).
- Performance in a warehouse depends on partitioning, clustering, and materialization choices — not just schema design.

## Modern open table formats

Apache Iceberg (the dominant standard as of early 2026, supported natively by all major cloud warehouses), Delta Lake, and Apache Hudi bring ACID transactions, schema evolution, and time travel to object storage. They allow maintaining a 3NF-like governance layer while serving star schema views for analytics, without physically moving data between systems.

## Naming conventions

- OLTP tables: singular or plural, snake_case — pick one convention and apply it consistently across the entire schema.
- OLAP tables: `fct_`, `dim_`, `stg_` prefixes (see `rules/data/sql-dbt.md`).
- Document grain, SCD behavior, and business definitions for every table and key attribute — an undocumented star schema becomes unreadable in six months.
