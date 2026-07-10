// Base: typescript-eslint.io/users/configs/ — v8.x (check for breaking
// changes on major bumps). strictTypeChecked / stylisticTypeChecked are
// explicitly NOT covered by typescript-eslint's semver stability
// guarantee — their rule set can change on a minor version bump.
//
// Use this instead of Biome only when the project needs
// eslint-plugin-react-hooks or type-aware rules Biome doesn't yet fully
// cover. Otherwise prefer examples/biome.json — see
// rules/typescript/lint-strict.md for the decision rule.
import js from "@eslint/js";
import { defineConfig } from "eslint/config";
import tseslint from "typescript-eslint";

export default defineConfig([
  js.configs.recommended,

  ...tseslint.configs.strictTypeChecked,
  ...tseslint.configs.stylisticTypeChecked,

  {
    languageOptions: {
      parserOptions: {
        projectService: true,
        tsconfigRootDir: import.meta.dirname,
      },
    },
  },

  {
    rules: {
      "@typescript-eslint/no-floating-promises": "error",
      "@typescript-eslint/consistent-type-imports": [
        "error",
        { prefer: "type-imports" },
      ],
      "@typescript-eslint/no-unused-vars": [
        "warn",
        { argsIgnorePattern: "^_", varsIgnorePattern: "^_" },
      ],
      "no-console": ["warn", { allow: ["warn", "error"] }],
    },
  },

  {
    files: ["**/*.{test,spec}.{ts,tsx}", "tests/**"],
    rules: {
      "@typescript-eslint/no-unsafe-assignment": "off",
      "@typescript-eslint/no-explicit-any": "off",
    },
  },

  // React projects — add on top:
  // eslint-plugin-react + eslint-plugin-react-hooks
  // "react-hooks/rules-of-hooks": "error"
  // "react-hooks/exhaustive-deps": "warn"
]);
