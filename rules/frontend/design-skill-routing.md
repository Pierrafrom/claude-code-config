# Frontend design skill routing

Several installed skills/plugins all respond to roughly the same trigger
("build/style this UI") but encode different, sometimes conflicting,
design philosophies. Claude Code doesn't run them concurrently, but
nothing prevents picking an inconsistent one project to project without
an explicit routing rule — this file is that rule.

## The skills in play

| Skill | Install type | Strength |
|---|---|---|
| `frontend-design` (Anthropic) | plugin | General-purpose baseline: bans generic fonts, forces an art direction before any code. The floor, not a specialist. |
| `impeccable` | plugin | Most complete for serious frontend work. Two explicit modes: **brand** (landing pages, marketing) vs **product** (dashboards, app UI) — 23 commands (`/impeccable polish`, `/impeccable audit`, `/impeccable critique`...), 27 anti-pattern rules. |
| `ui-ux-pro-max` | plugin | Persistent design-system generator: 84+ styles, 161+ palettes, 73+ font pairings, a `MASTER.md` + per-page overrides model. Best when a project needs a design system that stays coherent across many pages/components over time, not a one-off screen. |
| `design-taste-frontend` (taste-skill) | skill | Anti-slop for landing pages, portfolios, redesigns — infers direction from the brief, explicitly **not** meant for dashboards or data-heavy product UI. |
| `accesslint` | plugin | WCAG 2.2 accessibility — contrast, color-only signaling, link purpose, live-DOM audits. Orthogonal to the others; runs alongside any of them, never instead of. |
| `theme-factory` | skill | 10 pre-built theme tokens (colors + type pairing) for slides, docs, and landing pages — not a full design-system generator, a fast token source. |
| `emil-design-eng` / `review-animations` | skills | Animation construction / animation audit. Invoke on a specific component, not as a standing default. |
| `vercel-react-best-practices`, `vercel-composition-patterns`, `web-design-guidelines` | skills | Code-quality layer, not visual-direction — React/Next.js perf rules, component API patterns, and a 100+-rule UX/a11y linter (ARIA, focus states, semantic HTML). Always applicable regardless of which visual-direction skill is active. |
| `shadcn` | skill | Project-aware context for the shadcn/ui component library — activates automatically when a `components.json` is present. Not a visual-direction skill; it's the component-API layer underneath whichever direction is chosen. |

## Routing rule — pick ONE visual-direction skill per project

Never combine two direction-setting skills (`impeccable`, `ui-ux-pro-max`,
`design-taste-frontend`, bare `frontend-design`) on the same surface —
their aesthetic defaults can disagree, and mixing them produces
inconsistent output across a codebase. Decide by surface type:

- **Marketing / landing page / portfolio / one-off redesign** →
  `design-taste-frontend`, or `impeccable` in **brand** mode if the
  project already has `impeccable` conventions established.
- **Product UI / dashboard / app with data tables, forms, multi-step
  flows** → `impeccable` in **product** mode, or `ui-ux-pro-max` if the
  project needs a persistent, multi-page design system (`MASTER.md` +
  overrides) rather than a single-screen pass.
- **No strong opinion needed yet / earliest exploration** →
  `frontend-design` alone as the baseline until a direction is picked;
  don't reach for the specialists before there's a brief to react to.
- **Slides, internal docs, quick landing page needing consistent tokens
  fast, no full design-system investment justified** → `theme-factory`.

## Always-on, regardless of visual direction

- `accesslint` — accessibility is not a style choice, run it on any UI
  work.
- `web-design-guidelines` — the UX/a11y linter layer (ARIA, focus,
  semantic HTML) applies independently of which aesthetic was chosen.
- `vercel-react-best-practices` + `vercel-composition-patterns` — code
  -quality rules for any React/Next.js component, independent of visual
  direction.
- `shadcn` — activates on its own via `components.json` detection; no
  action needed to "choose" it.

## Punctual, not standing

- `emil-design-eng` / `review-animations` — invoke when a specific
  component's motion needs building or auditing, not as an always-on
  skill for every UI task.

## If a direction conflict is suspected mid-project

If a project already has an established direction (e.g. `impeccable`
brand mode was used for the initial landing page), don't introduce
`design-taste-frontend` or `ui-ux-pro-max` on a later page of the same
project without flagging the inconsistency explicitly — ask before
switching direction mid-project rather than silently blending two design
languages.
