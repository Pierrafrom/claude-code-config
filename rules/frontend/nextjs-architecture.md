# Next.js App Router — project structure

See `rules/common/project-architectures.md` for the governing rule: this
is a pattern to converge toward for legibility, not a mandate — adapt to
the project's actual size.

**Source**: nextjs.org/docs/app/getting-started/project-structure
(official). Re-check this source before trusting an older tree — anything
published before the App Router's stabilization (~2023) is obsolete: App
Router replaced Pages Router, React Server Components removed most API
routes, Server Actions replaced client-side mutations, Turbopack replaced
Webpack.

## Reference layout — a SaaS project that scales

```
my-app/
├── src/
│   ├── app/                          # App Router — file-system routing
│   │   ├── layout.tsx                # Root layout (required)
│   │   ├── page.tsx                  # Homepage /
│   │   ├── loading.tsx               # Global Suspense fallback
│   │   ├── error.tsx                 # Global error boundary
│   │   ├── not-found.tsx             # 404
│   │   │
│   │   ├── (auth)/                   # Route group — not part of the URL
│   │   │   ├── login/page.tsx
│   │   │   └── register/page.tsx
│   │   │
│   │   ├── (marketing)/              # Route group with its own layout
│   │   │   ├── layout.tsx
│   │   │   ├── pricing/page.tsx
│   │   │   └── about/page.tsx
│   │   │
│   │   ├── dashboard/
│   │   │   ├── layout.tsx            # Layout scoped to /dashboard
│   │   │   ├── page.tsx
│   │   │   ├── _components/          # _ = private to this route, not a segment
│   │   │   │   └── DashboardHeader.tsx
│   │   │   ├── _actions/             # Server Actions scoped to this route
│   │   │   │   └── update-settings.ts
│   │   │   └── settings/page.tsx
│   │   │
│   │   └── api/                      # Residual API routes (webhooks etc.)
│   │       └── webhooks/stripe/route.ts
│   │
│   ├── components/                   # Shared across routes
│   │   ├── ui/                       # UI primitives (shadcn, radix)
│   │   │   ├── Button.tsx
│   │   │   ├── Input.tsx
│   │   │   └── Modal.tsx
│   │   └── features/                 # Domain-aware reusable components
│   │       ├── auth/LoginForm.tsx
│   │       └── billing/PlanCard.tsx
│   │
│   ├── lib/                          # Application core — never imports from app/
│   │   ├── db/
│   │   │   ├── index.ts              # DB client (Prisma / Drizzle)
│   │   │   └── schema.ts
│   │   ├── auth/index.ts             # Auth.js / NextAuth config
│   │   ├── actions/                  # Global Server Actions
│   │   │   ├── user.ts
│   │   │   └── billing.ts
│   │   ├── validations/user.ts       # Shared Zod schemas
│   │   └── utils.ts                  # Pure utilities
│   │
│   ├── hooks/                        # React hooks — implicitly client-side
│   │   ├── useAuth.ts
│   │   └── useMediaQuery.ts
│   │
│   ├── stores/                       # Client state (Zustand, Jotai)
│   │   └── cart.ts
│   │
│   └── types/index.ts                # Global TypeScript types
│
├── public/
│   ├── logo.svg
│   └── og-image.png
│
├── .env.local                        # Never committed
├── .env.example                      # Committed template
├── next.config.ts
├── tsconfig.json
├── eslint.config.js
├── tailwind.config.ts
└── package.json
```

## Rules specific to this structure

- `_folder` inside `app/` is private to its parent route, not a URL
  segment.
- `(group)` is a route group: organizes routes without affecting the URL.
- The dependency graph flows one way: `app/ → components/ → lib/`.
  `lib/` never imports from `components/` or `app/` — see
  `rules/common/oop-design.md`'s Law of Demeter for the general principle
  this instantiates.
- `hooks/` and `stores/` are implicitly client-side — anyone importing
  from them knows they're opting into client rendering.
- Component conventions (props typing, `ReactNode`, hook extraction
  threshold) are in `rules/typescript/typescript-patterns.md`'s "React
  frontend specifics" section — this file is about where files live, that
  one is about how they're written.
