# Data science / MLOps — project structure

See `rules/common/project-architectures.md` for the governing rule.
Companion to `rules/data/data-engineering.md` (pipeline structure/
validation) and `rules/data/mlops-rag.md` (reproducibility, monitoring,
evaluation) — this file is specifically about directory layout.

**Source**: cookiecutter-data-science.drivendata.org (v2) — the
community-standard scaffold; re-check for structural changes on major
version bumps.

## Exploration / research project

```
my-ds-project/
├── data/
│   ├── raw/               # Raw data — IMMUTABLE, never edited, not even by hand
│   ├── interim/           # Intermediate transformations
│   ├── processed/         # Final data ready for modeling
│   └── external/          # Third-party data
│
├── notebooks/              # Jupyter — naming convention: N.N-initials-description
│   ├── 1.0-pba-initial-exploration.ipynb
│   └── 2.0-pba-feature-engineering.ipynb
│
├── src/                    # Importable source code (pip install -e .)
│   ├── __init__.py
│   ├── config.py           # Config values and paths
│   ├── dataset.py          # Data download / generation
│   ├── features.py         # Feature engineering
│   ├── modeling/
│   │   ├── __init__.py
│   │   ├── train.py
│   │   └── predict.py
│   └── visualization.py    # Reproducible plots
│
├── models/                 # Serialized models (.pkl, .pt, .onnx)
├── reports/
│   └── figures/
├── references/             # Data dictionaries, manuals
├── docs/                   # MkDocs / Sphinx
├── configs/                # Per-model hyperparameter YAML
│   └── model_v1.yaml
├── tests/
├── Makefile                # make data, make train, make report
├── pyproject.toml
└── README.md
```

**Rule**: notebooks hold exploration only. The moment a piece of code is
reused across two notebooks, it migrates into `src/` — see
`rules/common/coding-style.md`'s duplication rule ("2 times = watch it, 3
times = mandatory"), applied one usage earlier here because notebook code
is inherently harder to test and review than a module. `data/raw/` is
never edited, including by hand — see `rules/data/data-engineering.md`
for the point-in-time-correctness rationale this protects.

## Production pipeline (MLOps)

```
my-mlops/
├── src/
│   ├── data/
│   │   ├── ingestion.py
│   │   ├── validation.py     # Pandera / Great Expectations
│   │   ├── cleaning.py
│   │   ├── splitting.py
│   │   └── build_features.py
│   │
│   ├── models/
│   │   ├── model_a/
│   │   │   ├── train.py
│   │   │   ├── evaluate.py
│   │   │   └── predict.py
│   │   └── model_b/
│   │
│   ├── pipelines/            # Airflow / Prefect / MLflow DAGs
│   │   └── training_pipeline.py
│   │
│   └── serving/               # Serving API
│       └── app.py
│
├── configs/                   # Per-experiment YAML
├── data/                      # Same layout as the exploration project
├── models/                    # Versioned model artifacts
├── notebooks/
├── tests/
├── .dvc/                      # Data Version Control
├── mlflow/                    # Local MLflow tracking
├── Makefile
├── pyproject.toml
└── Dockerfile
```

For what belongs in each of these files operationally (feature/serving
skew, reproducibility triangle, monitoring levels, evaluation gates), see
`rules/data/mlops-rag.md` — this file only answers "where does it live,"
not "what does it need to do."
