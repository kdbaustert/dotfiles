---
paths:
  - "**/wp-content/**"
  - "**/wp-config.php"
  - "**/functions.php"
  - "**/class-*.php"
  - "**/uninstall.php"
  - "**/block.json"
  - "**/theme.json"
---

# WordPress

For WordPress plugins, themes and sites. It builds on `php.md`, and where the
two disagree this file wins.

## Coding standards

The WordPress Coding Standards (WPCS) replace the generic PHP defaults,
including double quotes and PSR naming:

- Tabs for indentation, spaces inside parentheses: `if ( $ready )`.
- Yoda conditions: `if ( true === $value )`.
- Single quotes unless the string interpolates or holds a single quote.
- `array()` rather than `[]`; WPCS 3 flags the short syntax.
- `snake_case` functions and variables, `Class_Name` classes in
  `class-class-name.php` files.
- Docblocks follow the WordPress PHP documentation standards, `@since`
  included.

## Prefix everything

Prefix every function, class, constant, option, transient, hook and global
with the project's prefix, or put the code in a namespace. Every translatable
string uses the project's text domain. Read both from `phpcs.xml` or the
plugin header; don't make them up.

## Security

- Every PHP file that isn't a template starts with
  `defined( 'ABSPATH' ) || exit;`.
- Sanitize early: `wp_unslash()` first, then `sanitize_text_field()`,
  `absint()`, `sanitize_email()` or `sanitize_key()` to fit the data.
- Escape late, at the echo: `esc_html()`, `esc_attr()`, `esc_url()`,
  `wp_kses_post()`, and the `esc_html__()` family for translated strings.
- Forms, AJAX and admin actions check a nonce (`wp_verify_nonce()`,
  `check_ajax_referer()`, `check_admin_referer()`) and a capability
  (`current_user_can()`). A nonce alone isn't authorization.
- Queries with variables go through `$wpdb->prepare()`. Prefer `WP_Query`,
  the options API and the meta functions over raw SQL.
- Every REST route has a real `permission_callback`. `__return_true` is only
  for routes that are public on purpose.

## The WordPress way

- Change behavior through hooks. Never edit core, a parent theme or a
  third-party plugin.
- Load assets with `wp_enqueue_script()` and `wp_enqueue_style()`, never a
  hard-coded tag.
- Use the HTTP API (`wp_remote_get()`, `wp_remote_post()`) instead of curl.
- Cache expensive work in transients or the object cache. Store large options
  with autoload off.
- Clean up in `uninstall.php`, not on deactivation.

## Tooling

WPCS isn't installed globally, so the global `phpcs` can't check against it.
Use the project's `vendor/bin/phpcs` with its `phpcs.xml` or `phpcs.xml.dist`.
If the project has neither, say so rather than linting with another standard.
Test with `WP_DEBUG` and `WP_DEBUG_LOG` on; new notices and warnings count as
failures.
