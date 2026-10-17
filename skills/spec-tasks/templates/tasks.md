# Tasks — <Feature name>

Spec: `docs/specs/<NNN-slug>/spec.md` · Plan: `docs/specs/<NNN-slug>/plan.md`

Order matters. `[P]` marks tasks that can run in parallel with the previous one.

- [ ] T1: Write failing test for <behavior> (R1)
  - Files: `tests/...`
  - Verify: `<command>` fails for the expected reason
- [ ] T2: Implement <minimal change> (R1)
  - Files: `src/...`
  - Depends on: T1
  - Verify: `<command>` passes
- [ ] T3 [P]: <next unit> (R2)
  - Files: `...`
  - Verify: `<command>`

## Final verification

`<end-to-end command from the spec's Verification section>`
