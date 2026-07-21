# Reasoning & planning tool routing — avoiding overlap

Three built-in mechanisms all respond to roughly the same trigger ("this
needs real thinking before acting" / "help me plan this"), but they solve
different problems and aren't interchangeable. Nothing prevented picking
one inconsistently task to task without an explicit routing rule — this
file is that rule, mirroring `rules/frontend/design-skill-routing.md`'s
role for the frontend design skills.

## The three mechanisms

| Mechanism | What it actually is | Requires user approval? | Context cost |
|---|---|---|---|
| **sequential-thinking (MCP)** | An inline reasoning aid — structured step-by-step scratchpad for one hard question, called mid-turn like any tool | No | Cheap — stays in the current turn, no mode switch |
| **Plan mode** (`EnterPlanMode`/`ExitPlanMode`) | A native mode change: explore the codebase, design an approach, present it for explicit sign-off before writing any code | Yes — the whole point of the mode | Free — uses the current conversation's context, nothing re-derived |
| **`Plan` subagent** (via `Agent` tool) | Delegates the planning work itself to a fresh, isolated agent that returns a finished plan | No (but its output is typically then reviewed with the user) | Expensive — cold start, re-derives context, per the `Agent` tool's own "don't spawn unless asked" guidance |

## Routing rule — pick by what's actually needed

- **Default for any non-trivial implementation task** ("add a feature",
  "refactor X", "multiple valid approaches exist"): use **plan mode**.
  It's the built-in default precisely for this — see its own trigger
  list (new feature, multiple valid approaches, multi-file change,
  unclear requirements, architectural decision). Don't reach for the
  `Plan` subagent as a substitute for this — plan mode is free (same
  conversation context) where the subagent is not.
- **Sequential-thinking is a tool used *inside* whichever workflow is
  already running**, not a competing workflow of its own. Invoke it
  explicitly (no auto-trigger, like any MCP) for the actual hard
  reasoning step — comparing architecture options, tracing a bug across
  multiple files, weighing a non-trivial trade-off — whether that
  reasoning happens during plan mode's exploration phase, mid-debugging,
  or in a normal turn with no mode change at all. It never requires user
  sign-off and never replaces presenting a plan for approval.
- **The `Plan` subagent is reserved for when delegation itself is the
  point** — same bar as any other subagent per the `Agent` tool's
  standing guidance ("don't spawn unless the user asks, or names the
  agent type"): the user explicitly wants an isolated/parallel planning
  pass, a second opinion produced without the main conversation's
  framing biasing it, or a plan produced in the background while work
  continues elsewhere. It is not the default path for "help me plan
  this feature" — plan mode is.

## Decision tree

```
Need to think before acting or building...
│
├── One hard question mid-task (bug across files, comparing 2-3 options,
│   a trade-off to weigh) — no need for user sign-off on a full plan
│   → sequential-thinking (MCP), inline, no mode change
│
├── Non-trivial implementation ahead: new feature, refactor, multiple
│   valid approaches, unclear scope, architectural choice
│   → EnterPlanMode (default) — explore, design, present for approval;
│     use sequential-thinking inside it for the hard reasoning steps
│
└── User explicitly asks for a subagent / independent planning pass /
    a plan produced in parallel or background
    → Agent tool with subagent_type: "Plan"
```

## Why this matters

Without this split, the natural failure mode is defaulting to whichever
mechanism was used last, or reaching for the heaviest tool (the `Plan`
subagent) out of habit when the free, in-context plan mode already
covers the need — burning a cold-start context re-derivation for no
benefit. Same failure class as the frontend design-skill overlap in
`rules/frontend/design-skill-routing.md`, different domain.
