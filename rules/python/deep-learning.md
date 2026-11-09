# Machine learning / deep learning (PyTorch) — project rules

Applies to Python projects that train or run ML/DL models. General Python
rules stay in `rules/python/*`; pipeline/validation in
`rules/data/data-engineering.md`; tracking, monitoring, RAG in
`rules/data/mlops-rag.md`; directory layout in
`rules/data/project-structure.md`. This file only covers what those do not:
the DL environment, determinism, training code, ML-specific tests, and how
Claude should drive long GPU jobs.

## Environment — PyTorch with uv

PyTorch ships each accelerator build on its own index, so a bare
`uv add torch` may resolve the wrong build. Route `torch`/`torchvision`
through an explicit index (source: docs.astral.sh/uv/guides/integration/pytorch/):

```toml
[tool.uv.sources]
torch = [{ index = "pytorch-cu128", marker = "sys_platform == 'linux' or sys_platform == 'win32'" }]
torchvision = [{ index = "pytorch-cu128", marker = "sys_platform == 'linux' or sys_platform == 'win32'" }]

[[tool.uv.index]]
name = "pytorch-cu128"
url = "https://download.pytorch.org/whl/cu128"
explicit = true  # only packages that opt in use this index
```

- `explicit = true` is mandatory: without it every package resolves against the PyTorch index.
- The `cu128` suffix is an example — take the current CUDA tag from pytorch.org/get-started/locally before generating a config (see freshness note below).
- Verify after `uv sync`: `uv run python -c "import torch; print(torch.__version__, torch.cuda.is_available())"` — the version should carry the local suffix (`+cu128`). No suffix = the sources table is missing or misspelled.
- Libraries published to PyPI declare plain `torch` and let users pick their build; the index pinning above is for applications.
- WSL2: GPU comes from the Windows driver — never install a Linux NVIDIA driver inside WSL.

## Determinism and reproducibility

- One `seed_everything(seed)` function at the entry point seeding `random`, `numpy`, `torch` (CPU + CUDA). The seed lives in the config and is logged with the run.
- DataLoader: pass a seeded `torch.Generator` and a `worker_init_fn`; otherwise workers silently diverge between runs.
- `torch.use_deterministic_algorithms(True)` only when bitwise reproducibility is required (costs speed, some ops raise). Otherwise accept GPU non-determinism and report **mean ± std over several seeds** (at least 3, 5 for a claim in a report) instead of one lucky run.
- Every run logs: resolved config, git SHA (and dirty flag), `uv.lock` hash, seed, library versions, hardware, dataset version/split ids. Extends the reproducibility triangle of `rules/data/data-engineering.md`.
- Splits are saved (indices or a deterministic hash rule), never re-drawn. Fit scalers/encoders/tokenizers on train only — leakage rules in `rules/data/mlops-rag.md`.

## Configuration of experiments

- Hyperparameters never hardcoded in the training script: a typed config (frozen dataclass or Pydantic model) loaded from YAML, overridable from the CLI. Hydra is the default when sweeps/multirun are needed; for a small project, YAML + Pydantic is enough (YAGNI).
- One config file per experiment under `configs/`, committed. The run directory stores the resolved copy.

## Training code

- Device-agnostic: one `resolve_device()`; tensors moved explicitly; no scattered `.cuda()`.
- Mixed precision via `torch.autocast` (bf16 when the GPU supports it). `torch.compile` only after measuring a bottleneck, never by default.
- Plain PyTorch is fine while learning or for small models; PyTorch Lightning (or equivalent) once checkpointing, multi-GPU or logging boilerplate dominates. Do not hand-roll a trainer framework.
- Checkpoints: save model + optimizer + scheduler + epoch + RNG state so training is resumable. Save weights as `safetensors` when sharing; load pickled checkpoints only from trusted sources with `torch.load(..., weights_only=True)`.
- Log training metrics to the tracker (MLflow/W&B per `rules/data/mlops-rag.md`) and operational events (epoch start/end, OOM, NaN loss) as JSONL per `rules/common/logging.md`. Never one log line per batch — aggregate.
- Fail fast on NaN/inf loss with context (batch id, lr, grad norm).
- Typing: annotate tensors precisely in docstrings (`Shape: (batch, seq, dim)`); `jaxtyping` is optional, worth it only when shape bugs recur.

## Tests — ML specifics (TDD still applies)

- **Shape/contract test**: forward pass on a tiny synthetic batch on CPU, asserting output shape and dtype. Runs in CI with no GPU.
- **Overfit-one-batch test**: the model must drive loss near zero on a single tiny batch — the cheapest catch for broken loss, optimizer or gradient flow.
- **Determinism test**: same seed ⇒ same loss after N steps on CPU.
- **Data tests**: schema/range checks on a sample (Pandera, `rules/data/data-engineering.md`), no train/test id overlap.
- Pytest markers `gpu` and `slow`, deselected by default (`-m "not gpu and not slow"`); CI runs the CPU subset. The 80% coverage target applies to library code (`src/`), not to one-off training entry scripts.
- Mock nothing in the tiny-model tests; mock network/dataset download only.

## Notebooks

- Exploration only (see `rules/python/python-patterns.md`): reused logic moves to `src/`.
- Strip outputs before commit with `nbstripout` (pre-commit hook) so diffs stay reviewable and no data leaks into git.
- Ruff on notebooks: relax `D`, `ANN`, `E402` for `*.ipynb` only.

## Lint adjustments for ML code

- ML code conventionally uses `X`, `X_train`, `Y`: enable ruff `N803`/`N806` ignores for `src/**/models` and `notebooks`, with the justification in the config comment — do not rename `X` to satisfy the linter.
- Add `NPY` (NumPy deprecations) and `PD` (pandas-vet) to `extend-select` when the project uses NumPy/pandas; `PERF` for hot loops.

## Data, artifacts, git

- Data, checkpoints, `mlruns/`, `wandb/`, `lightning_logs/`, `*.pt`, `*.ckpt`, `*.safetensors` are gitignored. Datasets and models are versioned with DVC (or the tracker's artifact store), never plain git.
- Large-file hygiene: before `git add`, check no artifact over ~1 MB slipped in.

## How Claude should drive training jobs

- **Never launch a full training run unprompted.** Order: unit tests → tiny-batch smoke run (1–2 steps, CPU or GPU) → short run → full run, each only after the previous passes. State the expected duration and GPU use before the full run and wait for a go.
- Long jobs run detached (Bash `run_in_background`, or `tmux`/`nohup`), writing JSONL logs to `logs/`. Do not poll in a loop; get notified on exit, then read results.
- Before any GPU run: `nvidia-smi` for free memory and processes. After an OOM: reduce batch size / enable gradient accumulation before touching model code.
- Debugging a failed run follows the global logs-first rule: `jq`/`rg` on ERROR lines and the last N lines of the run log. Never load a whole training log, checkpoint, or notebook with outputs into context.
- The project `CLAUDE.md` (not the global one) records the machine: GPU model/VRAM, CUDA tag, dataset paths, how to launch a run, tracker URI.

## Sources to watch (as of 2026-11-09)

Searched on this date; several results were community guides rather than official docs, so the CUDA tag and tool versions above must be re-checked before generating a real config (`rules/common/rule-freshness.md`).

| Domain | Canonical source | Change signal |
|---|---|---|
| uv + PyTorch indexes | docs.astral.sh/uv/guides/integration/pytorch/ | New CUDA tags, syntax changes |
| PyTorch builds, reproducibility notes | pytorch.org/get-started/locally, docs.pytorch.org/docs/stable/notes/randomness.html | Release notes (default flags such as `weights_only`) |
| Hydra | hydra.cc/docs | Major version |
| PyTorch Lightning | lightning.ai/docs | Major version |
