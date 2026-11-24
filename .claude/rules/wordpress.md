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
two disagree this file wins. JS, CSS and block code have their own rules in
`~/.claude/rules/wordpress-frontend.md`. Those only load on their own inside
`wp-content/`, so read that file yourself when a standalone plugin or theme
repo has JS or CSS to change.

## Coding standards

The WordPress Coding Standards (WPCS) replace the generic PHP defaults,
including double quotes, PSR naming and no trailing commas:

- Tabs for indentation, spaces inside parentheses: `if ( $ready )`.
- Yoda conditions: `if ( true === $value )`.
- Single quotes unless the string interpolates or holds a single quote.
- `array()` rather than `[]`; WPCS 3 flags the short syntax. A multi-line
  array has one item per line and a trailing comma after the last.
- Braces on every block, even one line. `elseif`, not `else if`.
- No closing `?>` at the end of a PHP-only file, and no short open tags.
- Lowercase short casts: `(int)`, `(bool)`, `(float)`.
- `snake_case` functions and variables, `Class_Name` classes in
  `class-class-name.php` files. Traits, interfaces and enums get `trait-`,
  `interface-` and `enum-` file prefixes. Other file names are lowercase and
  hyphenated.
- Hook names are lowercase with underscores and carry the prefix:
  `do_action( 'acme_after_save', $post_id )`.
- Docblocks follow the WordPress PHP documentation standards, `@since`
  included. Hooks you add get one too, with a `@param` per argument.

Where `php.md` bans `global`, the core globals are the exception:
`global $wpdb;`, `$post` and `$wp_query` are how WordPress hands those out.
Don't add globals of your own.

## Prefix everything

Prefix every function, class, constant, option, transient, meta key, hook,
script and style handle and global with the project's prefix, or put the code
in a namespace. Never use `wp_` or `__` as your own prefix. Every translatable
string uses the project's text domain. Read both from `phpcs.xml` or the
plugin header; don't make them up.

## Security

- Every PHP file that isn't a template starts with
  `defined( 'ABSPATH' ) || exit;`.
- Sanitize early: `isset()` first, then `wp_unslash()`, then
  `sanitize_text_field()`, `absint()`, `sanitize_email()` or `sanitize_key()`
  to fit the data. Check closed sets against an allowlist with
  `in_array( $value, $allowed, true )`.
- Escape late, at the echo: `esc_html()`, `esc_attr()`, `esc_url()`,
  `esc_textarea()`, `wp_kses_post()`, and the `esc_html__()` family for
  translated strings. Even values you think are safe.
- Data for JS goes through `wp_add_inline_script()` with `wp_json_encode()`,
  never PHP echoed into a script string.
- Forms, AJAX and admin actions check a nonce (`wp_verify_nonce()`,
  `check_ajax_referer()`, `check_admin_referer()`) and a capability
  (`current_user_can()`). A nonce alone isn't authorization. Check the
  narrowest capability, with the object ID when there is one:
  `current_user_can( 'edit_post', $post_id )`, not a role name.
- Register `wp_ajax_nopriv_` handlers only when logged-out visitors need them.
- Queries with variables go through `$wpdb->prepare()`, with `%i` for
  identifiers when the site requires WordPress 6.2 or later. Run
  `$wpdb->esc_like()` before adding `%` wildcards. Prefer `WP_Query`, the
  options API and the meta functions over raw SQL, and `$wpdb->insert()` and
  friends over hand-written writes.
- Every REST route has a real `permission_callback`. `__return_true` is only
  for routes that are public on purpose, with a comment saying so.
- `wp_safe_redirect()` then `exit;`. Uploads go through `wp_handle_upload()`
  or `media_handle_upload()` and `wp_check_filetype_and_ext()`. Never
  `include` a path built from input.

## The WordPress way

- Change behavior through hooks. Never edit core, a parent theme or a
  third-party plugin.
- Hook named functions or methods rather than closures, so others can
  unhook them.
- Load assets with `wp_enqueue_script()` and `wp_enqueue_style()`, never a
  hard-coded tag, and only on the screens that use them.
- Use the HTTP API (`wp_remote_get()`, `wp_remote_post()`) instead of curl,
  and `wp_safe_remote_get()` when a user supplies the URL. Likewise
  `wp_json_encode()`, `WP_Filesystem`, `wp_date()` and `wp_parse_args()`
  over the plain PHP versions.
- Change the main query in `pre_get_posts`, not by replacing `$wp_query`.
- Cache expensive work in transients or the object cache. Store large options
  with autoload off.
- Clean up in `uninstall.php`, not on deactivation.

## Translations

- Every string a user sees goes through `__()`, `_e()`, `_x()`, `_n()` or the
  `esc_html__()` family. The text domain is a literal string, never a
  variable or constant, or the extraction tools miss it.
- No variables inside the string. Use `sprintf()` with numbered placeholders
  (`%1$s`) when there's more than one, and put a `/* translators: */`
  comment on the line above saying what each one is.
- `_n()` for plurals, `_x()` when a word is ambiguous out of context. Translate
  whole sentences, never glued fragments.
- `number_format_i18n()` and `wp_date()` for numbers and dates.
- Plugins and themes hosted on WordPress.org load their translations on
  their own. Call `load_plugin_textdomain()` only for translations shipped
  some other way, and no earlier than `init`.

## Accessibility

Admin screens and front-end output aim for WCAG 2.2 AA:

- `<button>` for actions, `<a href>` for navigation, headings in order.
- Every field has a `<label>` tied to it. Related controls sit in a
  `<fieldset>` with a `<legend>`.
- Every `<img>` has `alt`, empty for decorative images.
- Everything works from the keyboard, and focus stays visible.
- Core's `screen-reader-text` class for hidden text, `wp.a11y.speak()` to
  announce changes made without a page load.
- Native HTML before ARIA. Where ARIA is used, keep its state in step with
  the UI.

## Tooling

WPCS isn't installed globally, so the global `phpcs` can't check against it.
Use the project's `vendor/bin/phpcs` with its `phpcs.xml` or `phpcs.xml.dist`.
If the project has neither, say so rather than linting with another standard.
Test with `WP_DEBUG` and `WP_DEBUG_LOG` on; new notices and warnings count as
failures.
