# Turborepo monorepo — project structure

See `rules/common/project-architectures.md` for the governing rule — only
reach for a monorepo when there are genuinely multiple related
apps/packages to coordinate. A single app doesn't need this; it needs
`rules/frontend/nextjs-architecture.md` on its own.

**Source**: turbo.build/repo/docs — re-check before trusting an older
layout.

## Reference layout

```
my-monorepo/
├── apps/                          # Deployable applications
│   ├── web/                       # Main Next.js app
│   │   ├── src/
│   │   ├── package.json
│   │   └── tsconfig.json          # Extends @repo/tsconfig/nextjs.json
│   │
│   ├── admin/                     # Admin dashboard (Vite + React)
│   │   ├── src/
│   │   └── package.json
│   │
│   └── api/                       # Node.js backend (Hono / Fastify)
│       ├── src/
│       └── package.json
│
├── packages/                      # Shared libraries
│   ├── ui/                        # Design system — React components
│   │   ├── src/
│   │   │   ├── Button/
│   │   │   │   ├── Button.tsx
│   │   │   │   ├── Button.test.tsx
│   │   │   │   └── index.ts
│   │   │   └── index.ts           # Package entry point
│   │   ├── package.json           # name: "@repo/ui"
│   │   └── tsconfig.json
│   │
│   ├── api-client/                # Typed client for the API
│   │   ├── src/
│   │   └── package.json           # name: "@repo/api-client"
│   │
│   ├── db/                        # Shared Drizzle/Prisma schema
│   │   ├── schema/
│   │   └── package.json           # name: "@repo/db"
│   │
│   └── config/                    # Shared tool configs — zero business logic
│       ├── eslint/base.js
│       ├── tsconfig/
│       │   ├── base.json
│       │   ├── nextjs.json        # Extends base.json
│       │   └── node.json
│       └── package.json           # name: "@repo/config"
│
├── turbo.json                     # Task pipeline
├── package.json                   # Root — workspaces: ["apps/*", "packages/*"]
├── pnpm-workspace.yaml
└── tsconfig.json                  # Root base
```

## `turbo.json` pipeline

```json
{
  "$schema": "https://turbo.build/schema.json",
  "tasks": {
    "build": { "dependsOn": ["^build"], "outputs": [".next/**", "dist/**"] },
    "dev": { "cache": false, "persistent": true },
    "lint": { "dependsOn": ["^build"] },
    "test": { "inputs": ["src/**/*.ts", "src/**/*.tsx", "tests/**"] }
  }
}
```

## Rules specific to this structure

- `apps/` = deployable product, depends on `packages/`, never the
  reverse.
- `packages/` = publishable libraries, no dependency on `apps/`.
- `packages/config` holds zero business logic — tool configuration only.
- Every package's `tsconfig.json` extends `@repo/config/tsconfig/base.json`
  rather than redeclaring compiler options — same "extend, don't
  duplicate" principle as `rules/common/config-standards.md`.
- One `CODEOWNERS` entry per package to make ownership explicit as the
  repo grows.
