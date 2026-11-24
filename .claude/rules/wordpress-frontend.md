---
paths:
  - "**/wp-content/**/*.js"
  - "**/wp-content/**/*.jsx"
  - "**/wp-content/**/*.ts"
  - "**/wp-content/**/*.tsx"
  - "**/wp-content/**/*.css"
  - "**/wp-content/**/*.scss"
  - "**/block.json"
---

# WordPress JS and CSS

For scripts, styles and blocks in WordPress plugins and themes. It builds on
`wordpress.md`, and where this file disagrees with the generic style rules it
wins. When the project has its own ESLint, Stylelint or Prettier config,
that config wins over everything here.

## JavaScript

The WordPress JavaScript Coding Standards:

- Tabs for indentation. Spaces inside parentheses, brackets and braces that
  hold something: `foo( a, b )`, `[ 1, 2 ]`, `{ key: value }`. Empty ones
  stay tight: `foo()`, `[]`.
- Single quotes, semicolons, braces on every block, `===`.
- `camelCase` variables and functions, `UpperCamelCase` classes and
  components, `SCREAMING_SNAKE_CASE` constants. An acronym keeps one case:
  `getId`, `DOMParser`.
- `const` first, `let` when it's reassigned, never `var` in new code.
- No new globals. Custom events and `data-` attributes carry the prefix.
- No jQuery in new code unless you're extending admin UI that already
  uses it.

## Blocks and the editor

- Build with `@wordpress/scripts` (`wp-scripts build` and `start`), and match
  the version the project already pins.
- Register blocks from `block.json` with the `apiVersion` the project's
  other blocks use (3 for new ones), then `register_block_type()` on the
  build folder in PHP.
- Import from the `@wordpress/*` packages. Don't bundle React; the
  `@wordpress/element` dependency gives you core's copy.
- Enqueue with the generated `*.asset.php` for the dependency list and
  version, never a hand-written list.
- `apiFetch` for the REST API, so the nonce and root URL come for free.
- `useBlockProps()` in both edit and save. `save()` stays deterministic, and
  any change to saved markup ships with a `deprecated` entry, or existing
  posts show the invalid-block warning.
- Editor UI uses `@wordpress/components`, which already handle keyboard and
  screen readers.
- Strings go through `__()`, `_x()`, `_n()` and `sprintf()` from
  `@wordpress/i18n` with the literal text domain, and the PHP side calls
  `wp_set_script_translations()` for each handle.
- Front-end scripts load in the footer or with `'strategy' => 'defer'`
  unless a dependency rules that out.

## CSS

The WordPress CSS Coding Standards:

- Tabs. One selector per line, the opening brace on the last selector's line,
  the closing brace on its own line.
- One declaration per line, one space after the colon, a blank line between
  rule sets.
- Lowercase hyphenated class names with the prefix: `.acme-card-title`. No
  IDs for styling, no over-qualified selectors like `div.acme-box`.
- Lowercase everything but strings. Short hex where it fits (`#fff`), double
  quotes in strings and attribute selectors, `0` without a unit, a leading
  zero on decimals, unitless `line-height`.
- Order properties by group: layout and position, then box model, then
  color and type, then the rest.
- No `!important` unless you're beating someone else's `!important`, with a
  comment naming whose.
- In block themes and blocks, use the `theme.json` presets
  (`var(--wp--preset--color--primary)`) rather than hard-coded values.
- Support RTL: logical properties like `margin-inline-start`, or an RTL file
  registered with `wp_style_add_data( $handle, 'rtl', 'replace' )`.
- Never remove a focus outline without a visible replacement. Wrap motion in
  `prefers-reduced-motion`.

## Tooling

`wp-scripts lint-js`, `wp-scripts lint-style` and `wp-scripts format` when
the project has `@wordpress/scripts`. They aren't global, so if the project
doesn't have it, use whatever linter it does have and say what you couldn't
check.
