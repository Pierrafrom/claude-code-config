---
name: design-system
description: Interactively defines and generates a complete, code-ready design system — color tokens (light/dark), typography, spacing, radius, elevation, motion, and grounded component variants — through a thorough discovery questionnaire (surface type, brand personality, inspirations, target component library) followed by real online research on whatever references the user provides. Orchestrates the already-installed frontend design skills/plugins (impeccable, ui-ux-pro-max, theme-factory, accesslint, shadcn, frontend-design) per rules/frontend/design-skill-routing.md rather than reimplementing their logic. Designed to pick up where Claude Design's visual exploration leaves off (a handoff bundle, or references gathered the same way) and turn a chosen direction into real, committed code. Use when the user wants to create/define/bootstrap a design system, a theme foundation, or brand tokens for a project.
---

# Design System — discovery, research, and generation

## Goal and non-goals

This skill's job is **discovery, research, routing, and assembly** — not
reinventing design intelligence that's already installed. Concretely:

- Don't hand-write a style/palette/typography library from scratch —
  `ui-ux-pro-max` already has 84+ styles, 161+ palettes, 73+ font
  pairings, and a persistent `MASTER.md` + per-page override engine. Call
  it.
- Don't hand-write anti-pattern/critique rules — `impeccable` already has
  27 of them plus `/impeccable audit`/`/impeccable critique`.
- Don't hand-compute WCAG contrast ratios — `accesslint` already does
  live-DOM contrast checks.
- Don't hand-write shadcn/ui component APIs — the `shadcn` skill already
  reads the project's `components.json` and knows the current CLI/theming
  conventions.
- **This skill's real value**: ask the questions none of the above ask on
  their own, research the specific references the user brings, decide
  which installed skill handles which piece (per
  `rules/frontend/design-skill-routing.md`), and assemble the result into
  one coherent, complete, code-ready deliverable instead of five
  disconnected outputs.

### Relationship to Claude Design

Claude Design (Anthropic Labs) is for interactively iterating on the
*look* — mockups, image-based iteration, sliders — and can produce a
handoff bundle for Claude Code. This skill is what runs **after** a
direction is chosen (from a Claude Design handoff bundle, or from
scratch via the questionnaire below): it turns that direction into an
actual, committed set of design tokens and grounded components, verified
for accessibility and typed correctly. If the user arrives with a
handoff bundle or an already-chosen direction, skip straight to Step 2
(Research) using what the bundle already specifies instead of
re-asking Step 1's questions from zero.

## Step 1 — Discovery questionnaire

Ask in groups, not all at once. Use `AskUserQuestion` for the
multiple-choice branches below; use open conversation for anything that
needs a real description (brand personality, existing constraints).
Take a reasonable default rather than blocking on a question nobody
cares about — but for this skill specifically, err on the side of
asking rather than assuming, since the whole point is a thorough intake.

### 1a — What's being designed

```
AskUserQuestion: "What kind of surface is this design system for?"
  - Marketing / landing / portfolio (brand-first)
  - Product UI / dashboard / app (data-dense, functional)
  - Both — a design system spanning marketing and product surfaces
  - A standalone, reusable design system (not tied to one project yet)
```

This answer drives the routing in Step 3 — see
`rules/frontend/design-skill-routing.md`'s brand-vs-product split.

### 1b — Brand personality (open conversation)

Ask for a short description in the user's own words: adjectives, mood,
what the product/company does, who it's for. Don't offer multiple choice
here — forcing personality into fixed buckets defeats the point of
asking.

### 1c — Existing constraints

```
AskUserQuestion: "Any existing brand constraints to work within?"
  - Yes — existing logo/colors/guidelines to respect
  - No — starting from a blank slate
```

If yes, ask for the actual assets/hex codes/brand guide now — research in
Step 2 should extend these, never contradict them without flagging it.

### 1d — Light/dark

```
AskUserQuestion: "Theme variants?"
  - Light and dark, user-toggleable (Recommended default)
  - Light only
  - Dark only
  - Follow system preference, no manual toggle
```

### 1e — Inspirations and references

```
AskUserQuestion (multiSelect): "What should inform the direction? (pick all that apply)"
  - Specific website(s) or product(s) I'll link/describe
  - Images/screenshots I'll provide
  - A known design system (Material, Human Interface, Fluent, Carbon, Polaris...)
  - A component library convention (shadcn/ui, Bootstrap, Radix, Chakra, Ant Design...)
  - No strong reference — infer from the brief alone
```

For each reference actually provided, get the concrete pointer now (URL,
image, name) — Step 2 researches each one for real, it doesn't
paraphrase a vague description.

### 1f — Target component library

```
AskUserQuestion: "Target component library?"
  - shadcn/ui (Recommended — matches rules/typescript conventions and the installed shadcn skill)
  - Bootstrap
  - Radix primitives, no shadcn layer
  - Other / custom — I'll specify
```

If shadcn/ui and no `components.json` exists yet in the target project,
flag that `shadcn init` needs to run first and confirm before running it
— see `rules/typescript/typescript-patterns.md`'s React frontend section.

### 1g — Component scope for this pass

```
AskUserQuestion (multiSelect): "Which component categories does this pass need to cover?"
  - Core primitives (button, input, card, badge, avatar) — minimum viable set
  - Forms (full form field set, validation states)
  - Navigation (nav bar, sidebar, tabs, breadcrumbs)
  - Data display (table, data table, charts)
  - Feedback/overlay (dialog, toast, tooltip, popover)
  - Full base set — everything above
```

### 1h — Accessibility target

```
AskUserQuestion: "Accessibility target?"
  - WCAG 2.2 AA (Recommended default, matches accesslint's baseline)
  - WCAG 2.2 AAA (stricter contrast — confirm this is a real requirement, not default caution)
```

### 1i — Deliverable confirmation

Confirm explicitly before generating: code artifacts (CSS variables /
Tailwind theme, token file, grounded component examples), not a written
spec document — this is meant to be dropped straight into a codebase,
consistent with the "code" option in Claude Design's handoff.

## Step 2 — Research pass

For every concrete reference gathered in 1e:

- **URL given**: `WebFetch` the site, note its actual color usage, type
  scale, spacing rhythm, and component conventions — don't guess from the
  name alone.
- **Image given**: read it directly (the Read tool handles images) and
  describe the concrete palette/typography/spacing observed.
- **Named design system** (Material, Fluent, Carbon, Polaris...):
  `WebSearch` for its current token documentation — these systems
  version their tokens, an old memory of "Material Design" is not the
  same as Material 3's current token set.
- **Named component library** (shadcn/ui, Bootstrap...): if it's
  shadcn/ui, defer to the installed `shadcn` skill for current
  conventions rather than researching it separately. For others,
  `WebSearch` their current theming approach.

Also verify, before generating anything, whether the CSS-variable/theming
convention in mind is still current — this is exactly the kind of
fast-moving detail `rules/common/rule-freshness.md` exists for (Tailwind
v3 vs v4 theming, OKLCH vs HSL color definitions, etc.). Flag it and
confirm with the user before assuming a remembered convention is still
right, rather than generating tokens in a now-outdated format.

## Step 3 — Route to installed skills, per the surface type

Apply `rules/frontend/design-skill-routing.md` directly using the Step 1a
answer:

- **Marketing/landing/brand** → `design-taste-frontend`, or `impeccable`
  in brand mode.
- **Product/dashboard** → `impeccable` in product mode, or
  `ui-ux-pro-max` if a persistent, multi-page system
  (`MASTER.md` + overrides) is the actual need.
- **Both / standalone reusable system** → `ui-ux-pro-max` as the primary
  generation engine — it's the one built for a system that must stay
  coherent across many surfaces, not a single screen.
- Always run `accesslint` on the resulting palette (both theme variants
  if light+dark) before finalizing — a design system that fails contrast
  in dark mode is not complete.
- Always ground component code through the `shadcn` skill if shadcn/ui
  was selected in 1f.
- Never invoke two direction-setting skills on the same system — see the
  routing file's explicit warning against blending visual directions.

## Step 4 — Assemble the complete system

A design system is not complete without every one of these — don't ship
a partial set silently, and don't add more than what Step 1g scoped:

- **Color**: full semantic token set (background, foreground, primary,
  secondary, accent, muted, destructive, success, warning, border, input,
  ring — adapt names to the target library's convention), both theme
  variants if requested.
- **Typography**: font families (heading/body/mono as relevant), type
  scale, weights, line-heights, letter-spacing.
- **Spacing scale.**
- **Radius scale.**
- **Elevation/shadow scale.**
- **Motion tokens** (duration, easing) — if the brief calls for
  meaningful motion, hand this specifically to `emil-design-eng` rather
  than inventing timing values by hand.
- **Breakpoints.**
- **Grounded component variants** for whatever was scoped in Step 1g,
  expressed in the target component library's actual API (shadcn
  `class-variance-authority` variants, Bootstrap Sass variables, etc.).

Output format: token definitions as actual code (CSS custom properties /
Tailwind theme config / the target library's native format — verified
current per Step 2), not prose describing what the tokens "should" be.

## Step 5 — Verify before declaring done

- Contrast-check every semantic color pair in every theme variant via
  `accesslint` — fix and re-check rather than shipping a known failure.
- Run `web-design-guidelines` against any generated component code.
- `tsc --noEmit` / lint clean per `rules/typescript/lint-strict.md` on
  any generated TypeScript.

## Step 6 — Final report

Summarize: what was generated (with file paths), which installed
skill(s) handled which piece and why (per the Step 3 routing), the
accessibility check results, and anything explicitly out of scope for
this pass (e.g. "data display components not covered — not selected in
1g").

## Guardrails

- Never invent brand colors, fonts, or tokens with no basis in the
  brief/inspirations/research — every non-obvious choice should trace
  back to something gathered in Step 1 or found in Step 2.
- Never run two visual-direction skills on the same system (Step 3).
- Never skip the accessibility verification in Step 5 to save time.
- If the target project has no `components.json` and shadcn/ui was
  chosen, confirm before running `shadcn init` — it changes project
  files.
- If a Claude Design handoff bundle already answers a Step 1 question,
  don't re-ask it — use what the bundle specifies and say so explicitly.
