---
paths: ["**/auth.ts", "**/auth/**", "**/auth-client*.ts", "**/*auth*.ts"]
---

# Authentication — library-agnostic rules + Better Auth specifics

Threat checklist is in `rules/common/security-web-api.md`; this file is
about *how auth is wired*. Prefer a maintained auth library over
hand-rolled sessions/crypto.

## Principles (any library)

- **Isolate the auth library behind one module** (e.g. `auth.ts` on the
  server, one client file per platform). The rest of the code depends on
  a small interface (`getSession`, `requireUser`), so replacing the
  library is a bounded change. Document the exit path in
  `docs/decisions/`.
- Pin the version exactly; newer or recently-acquired projects deserve a
  watch on release notes and ownership/licence changes.
- Session secret: long random value from the environment, never in the
  repo; generate with the library's CLI, enforce minimum length at
  startup.
- Trusted origins / redirect URIs are an explicit allow-list containing
  only the real web origin and the app's scheme; development-only
  wildcards are gated by `NODE_ENV` and never shipped to production.
- E-mail verification and password reset require a transactional e-mail
  provider with SPF/DKIM/DMARC configured — plan it, it is not optional.
- Social login: if iOS offers any, Sign in with Apple is mandatory.
- Rate limiting and bot protection are the application's job even when
  the library ships defaults; a custom limiter store must consume
  atomically.

## Better Auth (TypeScript)

Verified against the official docs (2026-10); re-check on version bumps.

- Drizzle adapter: `drizzleAdapter(db, { provider: "pg" })`.
- **Schema drift**: generate auth tables with the library CLI
  (`npx auth@latest generate`) and re-run it whenever a plugin is added.
  Hand-maintained table copies drift.
- Secret: `npx auth@latest secret`; `BETTER_AUTH_SECRET` at least 32
  random characters.
- Expo: `@better-auth/expo` server plugin plus `expoClient({ storage:
  SecureStore })` on native; web uses the standard client with cookies.
  `trustedOrigins` includes the app scheme (`myapp://`) and the web
  origin; `exp://` wildcards only in development.
- Rate limiting: built-in limiter is configurable; for multi-instance
  deployments supply a shared store whose `consume` is atomic.

## Sources to watch (as of 2026-10-17)

| Domain | Canonical source | Change signal |
|---|---|---|
| Better Auth | better-auth.com/docs | Releases, plugin/schema changes, ownership news |
| OWASP auth & session cheat sheets | cheatsheetseries.owasp.org | Updated guidance |
