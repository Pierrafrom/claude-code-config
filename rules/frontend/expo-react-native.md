---
paths: ["**/app.json", "**/app.config.*", "**/eas.json", "**/metro.config.*", "**/*.native.ts", "**/*.native.tsx", "**/*.web.ts", "**/*.web.tsx", "**/babel.config.*", "**/global.css"]
---

# Expo / React Native — one codebase for web, iOS, Android

Companion to `rules/typescript/*` (typing, lint) and
`rules/frontend/design-skill-routing.md` (visual direction). Fast-moving
ecosystem: see "Sources to watch" and `rules/common/rule-freshness.md`
before applying a pinned version below to a real project.

## Structure and routing

- Expo Router: file-based routing under `app/`. Business logic, API
  clients and shared types live outside `app/` (feature folders or a
  `packages/shared` workspace) so route files stay thin.
- **Platform-specific files by extension**: `thing.web.tsx` /
  `thing.native.tsx` (or `.ios.` / `.android.`). Expo resolves the right
  one at bundle time — no runtime `Platform.OS` branching for whole
  modules.
- Prefer native stack and native tabs over JS-based navigators when the
  SDK offers them.
- Web as SPA (`web.output: "single"`) is fine for authenticated apps; the
  static/server rendering modes are for SEO-driven sites, and Expo's
  server rendering may still be pre-stable — check the changelog before
  relying on it.

## Auth client and secrets — never share a file across platforms

- Native session storage = `expo-secure-store`. Web = `HttpOnly` cookies.
  Split the auth client per platform (`auth-client.ts` /
  `auth-client.web.ts`); importing SecureStore in a web bundle breaks it.
- Nothing prefixed `EXPO_PUBLIC_` is secret — it ships inside the bundle.
  Secrets stay server-side.

## Lists, images, animation

- Long lists: virtualized (FlashList or FlatList), never `.map()` over a
  full collection in a `ScrollView`. Stable `keyExtractor`; no inline
  anonymous components in `renderItem` for big lists.
- Animation with Reanimated: keep work on the UI thread (worklets);
  never drive animation from React state updates.
- Optimize images (sized thumbnails, cached by URL); watch the web bundle
  size and split by route.

## Monorepo (pnpm)

- Since Expo SDK 54, isolated pnpm installs are supported; a
  `create-expo-app` project still defaults to `node-linker=hoisted`.
  Hoisted is the conservative choice for Metro — verify isolated mode on
  the actual project before switching.
- Pin the SDK, `react-native` and `react` together (use `npx expo install`
  / `expo install --check` for native deps so versions match the SDK).
- Type-only imports across workspaces (e.g. the API's `AppType`) use
  `import type` so no server code reaches the bundle.

## Updates and stores

- EAS Update (OTA) is for JavaScript fixes; set `runtimeVersion` (policy
  `appVersion` is the simple default) so an update never targets an
  incompatible native build. No major behavior change via OTA — store
  rules.
- If any social login is offered on iOS, Sign in with Apple becomes
  mandatory. Account deletion must be possible in-app (Apple).
- The deep-link scheme is an identifier shared by the app config, the
  auth `trustedOrigins` and universal-link files — rename it in one
  pass, never piecemeal.

## Styling with NativeWind

- **v4** = Tailwind CSS 3.x + babel preset + Metro wrapper; stable.
  **v5** = Tailwind 4 (PostCSS plugin, plain `babel-preset-expo`) and was
  still a release candidate as of 2026-10 — don't migrate before stable,
  and avoid UI kits that require v5 until then. Never mix v4 and v5
  setup instructions.
- shadcn/ui is web-only; on native, build components in-house (tokens in
  the Tailwind theme) — see `rules/frontend/design-skill-routing.md`.
- Never encode information by color alone (rarity, status): pair color
  with an icon, label or shape (WCAG 2.2).

## Sources to watch (as of 2026-10-17)

| Domain | Canonical source | Change signal |
|---|---|---|
| Expo SDK, Router, EAS | docs.expo.dev | SDK release notes / changelog |
| NativeWind | nativewind.dev | v5 stable release |
| Reanimated / Worklets | docs.swmansion.com/react-native-reanimated | Major bumps |
| App store rules | developer.apple.com/app-store/review/guidelines | Guideline updates |
