# MLOps / LLMOps / RAG — reproducibility, evaluation, operations

## Reproducibility — the foundational rule

Given identical inputs (code + data + environment + hyperparameters), a training or inference build must produce identical outputs. This is what makes debugging, rollback, and historical behavior analysis possible.

**What to version together as a unit:**
- Training data (or a pointer to the exact snapshot)
- Code (pinned via git commit SHA)
- Environment (pinned `uv.lock` or equivalent)
- Hyperparameters and model config

Use **MLflow** or **W&B** as the experiment tracking backend — not ad hoc logging to files.

## Feature engineering and data leakage

**Feature/training-serving skew** (features computed differently between training and production) is responsible for a large share of silent model failures. Define features in a single shared location used by both the training pipeline and the serving layer.

**Point-in-time correctness**: any feature or aggregate must only use information genuinely available at time T in the real world. Computing a feature with future information causes data leakage that manifests as inflated training metrics and unexplained production underperformance.

## RAG pipelines — specific failure points

RAG introduces failure modes that differ from standard ML:

| Failure point | What to check |
|---|---|
| Retrieval quality | Are the right documents being retrieved? |
| Context relevance | Is the retrieved context actually used by the model? |
| Knowledge base freshness | Is the vector store up to date? |
| Embedding drift | Do query embeddings stay aligned with document embeddings over time? |

**Version everything that constitutes the model's knowledge:**
- Document indexes
- Embedding models (name + version)
- Chunking configuration (chunk size, overlap, strategy)

Any change to the retrieval pipeline is a change to the model's effective knowledge — track it as such.

**Guardrails (mandatory before user-facing production):**
- Input guards: prompt injection detection, PII detection, malicious intent detection.
- Output guards: PII leakage, hallucination detection, toxic content, format compliance.

**Evaluation in CI/CD:**
- Evaluate with RAGAS (or equivalent) on a representative test set. Define blocking thresholds — if a quality metric falls below the threshold, the pipeline must fail and block deployment. This prevents a prompt regression from reaching production silently.

## Monitoring

Three levels, all required:

| Level | Metrics |
|---|---|
| Infrastructure | Latency p50/p90/p99, error rate, GPU/CPU utilization |
| Model | Prediction distribution, confidence calibration, performance by segment |
| Data | Schema changes, missing fields, feature distribution drift |

For RAG specifically: hallucination rate, token cost per query, retrieval precision/recall.

## Cost optimization (LLMOps)

- Route simple requests to smaller/cheaper models — not every query needs the largest model.
- Cache responses for repeated or near-identical queries.
- Batch and chain inference calls to reduce per-token overhead.

## Governance and compliance

Explainability, traceability, and audit trail for every model decision are now a regulatory requirement under the EU AI Act (2025), not an optional best practice.

For high-risk outputs (legal, medical, financial):
- Always include a human review step and an escalation mechanism.
- Record human decisions in run metadata for audit purposes.
