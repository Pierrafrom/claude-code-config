# Web / API security — checklist

Application-level complement to the DevSecOps section of
`rules/devops/devops.md` (secrets managers, scanning, CI supply chain —
not repeated here) and to the "Security" bullets in
`rules/common/coding-style.md`. Structured on the OWASP API Security
Top 10 (2023 edition); applies to any HTTP API with user accounts.

## Authorization (OWASP API1, API3, API5)

- **Object-level authorization on every endpoint that takes an id** and
  acts on the object: verify the caller may touch *that* object, not just
  that they are logged in. Comparing session user id to the path id is
  insufficient on its own.
- Unpredictable ids (UUID) help but are never a substitute for the check.
- Return only the fields the caller may see (explicit response schemas);
  accept only the fields the caller may set (no mass assignment).
- Function-level checks: admin/moderation routes are separate and
  explicitly guarded.
- Tests for authorization logic (another user's id must fail) are
  required, and failing tests block deploy.

## Authentication and sessions (API2)

- Auth endpoints (sign-up, login, reset, verification) get **stricter
  rate limits** than the rest of the API, plus a bot challenge on
  sign-up (e.g. Turnstile) and verified e-mail before sensitive actions.
- Web: `HttpOnly`, `Secure`, `SameSite` cookies. Mobile: platform secure
  storage (Keychain/Keystore via SecureStore). No tokens in `localStorage`
  or URLs.
- Rate limit by account/user/client as well as IP — IP alone is trivially
  evaded and punishes shared networks.

## Resource consumption and business-flow abuse (API4, API6)

- Limits on request size, pagination (`max` page size), query cost and
  concurrency; timeouts everywhere.
- Identify **sensitive business flows** (free-resource claims, trading,
  bidding, referrals) and give each its own limits, anomaly detection
  and audit log; assume farming/bot abuse for anything with free value.
- Layer limits: CDN/WAF in front, application limiter behind. The
  limiter store must be atomic (check-and-increment in one operation).

## Transport, config, secrets (API7-API10)

- HTTPS only; HSTS; CORS with an explicit origin allow-list (never
  reflect `Origin`).
- Secrets only in the environment/secrets manager, minimum length and
  entropy enforced at startup (fail-fast on missing/weak values);
  rotation possible without redeploying code.
- Databases and caches not reachable from the internet; least-privilege
  roles; separate migration and runtime credentials.
- Inventory of API versions/endpoints; old mobile app versions stay in
  the wild, so version the API and support a minimum-version gate.
- Consume third-party APIs defensively (timeouts, validation of responses,
  identifiable User-Agent, respect rate limits).

## Validation and logging

- Validate every external input server-side with a schema (Zod in
  TypeScript, Pydantic in Python). Client-side validation is UX only.
- Never log secrets or personal data; do log security-relevant and
  economic events (who, what, when, outcome) in the structured format of
  `rules/common/logging.md`.
- Dependencies: track advisories for the web/auth/ORM stack and apply
  patches promptly (`rules/devops/devops.md` for tooling).

## Sources to watch (as of 2026-10-17)

| Domain | Canonical source | Change signal |
|---|---|---|
| OWASP API Security Top 10 | owasp.org/API-Security | New edition |
| OWASP Cheat Sheet Series | cheatsheetseries.owasp.org | Updated sheets (auth, session, CORS) |
