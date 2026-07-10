# DevOps — CI/CD, Docker, IaC, observability, security

## Routing — apply by project context

| Project includes | Apply sections |
|---|---|
| Dockerfile / containerization | Docker + DevSecOps |
| CI/CD pipeline (GitHub Actions, GitLab CI) | Git workflow + CI/CD + DORA |
| IaC (Terraform, Kubernetes manifests) | GitOps/IaC |
| Any deployment to production | DevSecOps (always) |

## Git workflow

- **Trunk-based development** (or short-lived feature branches, max 1 day) over long-lived branches — the primary lever for moving from medium to elite DORA metrics. Elite teams maintain fewer than three active branches at any time.
- Keep PR size around **400 lines** — larger PRs directly increase lead time and change failure rate.
- **Feature flags by type** — distinguish by lifecycle and purpose:
  - *Release toggles*: short-lived, decouple deploy from release
  - *Ops toggles*: long-lived, circuit-breaker-style operational control
  - *Experiment toggles*: A/B test duration
  - *Permission toggles*: permanent, access control
  - Conflating these four types is a major source of technical debt.

## CI/CD pipeline

- Target **under 10 minutes** for the full pipeline — slow CI discourages frequent commits.
- **Parallelize tests** — never run them sequentially if they can be independent.
- **Artifact immutability**: build once, promote the same artifact across environments. Never rebuild between staging and production — it breaks reproducibility and makes rollback unreliable. All artifacts (Docker images, VM images) must be versioned and immutable.
- **Security gates** embedded in the pipeline (shift-left):
  - SAST (e.g. Semgrep)
  - DAST (e.g. OWASP ZAP)
  - Secret scanning (e.g. Gitleaks)
  - Dependency audit / container scan (e.g. Trivy, Snyk)
  - Scan every built image for vulnerabilities before pushing to a registry
  - Scan IaC templates (Terraform, CloudFormation) for overly permissive IAM or unencrypted buckets
- Fail the pipeline if test coverage drops below the defined threshold or if critical vulnerabilities are found.

## GitOps and Infrastructure as Code

- **Git is the single source of truth** for infrastructure and application configuration — all production changes go through Git commits, reconciled by automated agents (Argo CD, Flux), never applied manually.
- **Never commit Terraform state** (`.tfstate`) to Git — use a remote backend (S3 + DynamoDB lock) to prevent concurrent conflicts.
- Organize Terraform in **reusable modules** (`vpc`, `rds`, `ec2`) separated from environments (`dev`, `staging`, `prod`).
- Run scheduled `terraform plan` jobs to detect **configuration drift** between declared and actual state.
- **Immutable infrastructure**: replace, don't mutate. Instead of patching a running instance, provision a new one from a base image and deploy it. Eliminates configuration drift and ensures repeatable deployments.
- Enforce **pull request workflow for all infra changes** — branch protection rules requiring peer review and automated checks (lint, validation) before merge.

## Docker

**Image construction:**
- **Multi-stage builds** always — separate the build stage from the runtime image. The final image contains only what is needed at runtime. This is the single most impactful technique for reducing image size and attack surface.
- **Minimal base images** (`alpine`, `distroless`, or Docker Hardened Images) over full OS images (`ubuntu`, `debian`) — hundreds of unnecessary packages each represent a potential vulnerability.
- **Pin images by digest**, not by tag — `latest` is mutable and unpredictable.
- Use the **exec form** for `CMD` and `ENTRYPOINT`: `CMD ["executable", "arg1"]`, never the shell form.

**Security at build time:**
- **Never embed secrets**, credentials, or private keys in the image. Use `.dockerignore` to exclude sensitive files from the build context.
- Rebuild images regularly to pull base image security patches — a built image is a frozen snapshot that becomes stale.
- Generate a **SBOM** (Software Bill of Materials) for each image — required for rapid CVE exposure assessment and will be mandatory under the EU Cyber Resilience Act (September 2026).

**Security at runtime:**
- Run containers as **non-root** (`USER` directive in Dockerfile). Use multi-stage builds to install as root then switch to non-root for the runtime stage.
- Use a **read-only filesystem** when the application does not need to write to disk.
- **Drop all Linux capabilities** by default, re-add only those explicitly required.
- **Never mount the Docker socket** into a container — it is a privileged escalation to the host.
- Apply `no-new-privileges` security option.

**Operational:**
- Define explicit **resource limits** (memory + CPU) to prevent resource starvation in production.
- Implement **health checks** and **graceful shutdown** handling for proper orchestrator integration.

## Observability

- **OpenTelemetry** is the industry standard for instrumentation — use it for vendor-neutral telemetry rather than a proprietary SDK.
- Route telemetry through an **OpenTelemetry Collector** — it centralizes enrichment, masking, sampling, and export to multiple backends without changing application code.
- Apply governance at the telemetry origin: mask sensitive data, configure sampling, enforce retention policies.
- Elite observability requires alerts that trigger within minutes of a production problem — this implies structured logs, metrics with alert thresholds, and distributed tracing for complex systems.
- Monitor container runtime behavior for anomalous syscalls, suspicious file access, or unexpected network connections (e.g. Falco). Centralize container logs in a visualization stack.

## DevSecOps and secrets management

- **Never store secrets in code or versioned config files.** Use a dedicated secrets manager (HashiCorp Vault, AWS Secrets Manager, GitHub Encrypted Secrets).
- **Pin third-party CI actions by commit hash**, never by mutable tag — supply chain attacks have already targeted popular GitHub Actions to exfiltrate secrets from runner memory.
- Apply **seccomp profiles** to restrict available syscalls to what the container actually needs.

## Deployment strategies

- Use **canary or progressive deployments** — release to a small percentage of traffic first. If metrics degrade, stop before the impact propagates. (Popularized by Netflix; standard practice for elite teams.)
- **Decouple deployment from release** using feature flags — code can be deployed to production but activated only when ready, without waiting for all features to be complete.

## DORA metrics — measuring DevOps performance

The four DORA metrics: **deployment frequency**, **lead time for changes**, **change failure rate**, **mean time to recovery (MTTR)**.

Elite-tier targets:
- Lead time: under 1 hour
- MTTR: under 1 hour
- Deployment frequency: on-demand (multiple per day)

**Anti-gaming**: use consistent, clear definitions. Artificially fragmenting deployments or prematurely closing incidents to improve numbers is a classic trap — focus on practices that drive real progress (automated tests, refined pipelines, blameless post-mortems). Moving from medium to elite typically requires architectural changes (trunk-based development, feature flags, smaller services) coupled with a cultural shift on deployment risk tolerance.
