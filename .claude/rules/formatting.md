---
paths:
  - "**/*.js"
  - "**/*.jsx"
  - "**/*.mjs"
  - "**/*.cjs"
  - "**/*.ts"
  - "**/*.tsx"
  - "**/*.mts"
  - "**/*.cts"
  - "**/*.json"
  - "**/*.json5"
  - "**/*.jsonc"
  - "**/*.css"
  - "**/*.scss"
  - "**/*.less"
  - "**/*.html"
  - "**/*.htm"
  - "**/*.html.tpl"
  - "**/*.vue"
  - "**/*.hbs"
  - "**/*.handlebars"
  - "**/*.graphql"
  - "**/*.gql"
  - "**/*.md"
  - "**/*.markdown"
  - "**/*.mdx"
  - "**/*.yml"
  - "**/*.yaml"
  - "**/*.php"
---

# Formatting with Prettier

Prettier formats every file you write or change in any language it
supports, built in or through an installed plugin:

- JavaScript (including JSX and Flow) and TypeScript: `.js`, `.jsx`, `.mjs`,
  `.cjs`, `.ts`, `.tsx`, `.mts`, `.cts`
- JSON: `.json`, `.json5`, `.jsonc`, plus `package.json` and other JSON
  config files
- CSS, SCSS and Less: `.css`, `.scss`, `.less`
- HTML, Vue and Angular templates: `.html`, `.htm`, `.vue`, and `.html.tpl`
  through the override in `~/.prettierrc`
- Handlebars and Ember (Glimmer): `.hbs`, `.handlebars`
- GraphQL: `.graphql`, `.gql`, and GraphQL in tagged template literals
- Markdown and MDX: `.md`, `.markdown`, `.mdx`, including the code blocks
  inside them
- YAML: `.yml`, `.yaml`
- PHP, through `@prettier/plugin-php`, under the limits in the PHP section
  below

A language that needs a plugin you don't have installed globally (Svelte,
Astro, XML and so on) gets Prettier only when the project ships that plugin.
Don't format by hand, and don't argue with Prettier's output in review.

## Which config

- The project's own Prettier config (`.prettierrc*`, `prettier.config.*` or
  a `prettier` key in `package.json`) wins, along with its
  `.prettierignore`.
- With none, Prettier walks up to `~/.prettierrc`, which is linked from
  dotfiles. Don't add a config to a project that doesn't have one; ask
  first.
- `wp-scripts format` in a WordPress project and `npm run format` (or the
  project's equivalent script) count as Prettier. Use the script when there
  is one.

## Which binary

Use the project's pinned copy first: the `format` script, or
`pnpm exec prettier` / `npx prettier` when `prettier` is in
`devDependencies`. The global pnpm `prettier` is only for projects without
one, since a different major version can format the same file differently.

## PHP

The project's PHP formatter wins over Prettier: Pint in Laravel,
`vendor/bin/phpcbf` with WPCS in WordPress, `php-cs-fixer` or `phpcs` where
the project configures them. Prettier with `@prettier/plugin-php` is the
fallback only for PHP projects with none of those. Never run two PHP
formatters on the same file.

## How to run it

- Format only the files you changed: `prettier --write <files>`. Never run it
  over the whole repo unless the task is to reformat the repo.
- If formatting a file you touched rewrites lines you didn't change, keep
  that out of the task's diff and say so. A repo-wide reformat goes in its
  own commit.
- Before finishing, run `prettier --check` on the changed files and fix
  anything it reports.
- When ESLint and Prettier both run, Prettier owns formatting. Don't add or
  keep ESLint style rules that fight it (`eslint-config-prettier` turns them
  off).
- Leave `// prettier-ignore` for code where layout carries meaning, like a
  hand-aligned matrix or table, with a reason on the line above.
