---
paths:
  - "**/*.php"
  - "**/composer.json"
---

# PHP

Rules for PHP you write or change. The repo's own style and tooling come
first, then `wordpress.md` or `laravel.md` for those projects, then this file.
The formatting defaults (120 cols, double quotes, no trailing commas) live in
the *Code style* task rules and aren't repeated here.

## Which framework

Check `composer.json` and the tree before writing code. The framework rules
only load on their own once a matching file is opened, so read them yourself
when the project fits:

- `laravel/framework` in `require`: read `~/.claude/rules/laravel.md`.
- A `Plugin Name:` or theme `style.css` header, a `wp-content/` folder, or
  `wp-coding-standards/wpcs` in `require-dev`: read
  `~/.claude/rules/wordpress.md`.

## Language

- Target the version in `composer.json`'s `require.php`, or the plugin's
  `Requires PHP` header, else 8.1. Nothing newer than that: readonly classes
  are 8.2, typed class constants 8.3, property hooks 8.4.
- `declare(strict_types=1);` in new files unless the project's existing files
  leave it out.
- Native types on every parameter, return and property the target allows.
  The docblock carries only what native types can't say.
- Enums for closed sets, constructor promotion and `readonly` for value
  objects, `match` over a `switch` that only maps values.
- `===` and `!==`, and `in_array()` with `true` as the third argument.
- No `@` error suppression, `extract()`, `eval()`, `global` or mutable static
  state outside what the framework itself does.

## Security

- SQL uses bound parameters only, through PDO or the framework's query
  builder. Column names and `ORDER BY` can't be bound, so match them against
  an allowlist.
- Escape output for where it lands: HTML, attribute, URL or JS. A template's
  auto-escaping counts. Raw output needs a reason next to it.
- Validate input at the boundary against an allowlist. Reject bad input
  rather than cleaning it and carrying on.
- `password_hash()` and `password_verify()` for passwords, `random_bytes()`
  or `random_int()` for tokens, `hash_equals()` to compare them.
- Never `unserialize()` anything a user could have touched. Use JSON.
- Uploads: check the type server-side, rename the file and store it outside
  the web root.
- Secrets come from env or config, never from code. Every state-changing
  request authenticated by a cookie checks a CSRF token.

## Tooling

Use what the project pins first: `vendor/bin/*` and the `scripts` in
`composer.json`. Installed globally here: `php-cs-fixer`, `phpcs` and `phpcbf`
(with Automattic's Neutron standard and WPCS), `phpstan`, `phpmd` and
`phpunit`. Larastan, Pest and Pint aren't global, so use them only when the
project requires them, and ask before adding one. Run the global `phpstan` and
`phpmd` only against a project's own `phpstan.neon` or PHPMD ruleset; without
one there's no agreed level to hold the code to.

Before calling PHP work done, run:

1. `php -l` on every changed file. It parses with the installed PHP, which
   can be newer than the target, so it won't catch syntax the target lacks.
2. The project's formatter or linter, in check mode, on the changed files.
3. Its static analysis, if it has any configured.
4. The tests that cover the change.

Say which of these the project doesn't have rather than skipping them quietly.
