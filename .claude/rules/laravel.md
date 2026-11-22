---
paths:
  - "**/artisan"
  - "**/bootstrap/app.php"
  - "**/app/Http/**"
  - "**/app/Models/**"
  - "**/app/Providers/**"
  - "**/routes/*.php"
  - "**/database/migrations/**"
  - "**/database/factories/**"
  - "**/*.blade.php"
---

# Laravel

For Laravel apps and packages. It builds on `php.md`, and where the two
disagree this file wins.

## Version

Read the installed Laravel version from `composer.lock` and write for that
version's docs. Directory layout and bootstrapping changed in Laravel 11, so
copy the app's own structure rather than an older tutorial's. If the project
requires `laravel/boost`, use its tools for docs, routes, schema and logs
before guessing.

## Structure

- Thin controllers. Validation goes in FormRequest classes, business logic in
  action or service classes.
- Eloquent and the query builder first. Raw SQL only when they can't express
  it, and always with bindings.
- Every model declares its relationships, `casts` and `$fillable`. Never
  `$guarded = []`.
- API Resources shape JSON responses.
- Slow work (mail, third-party calls, imports) goes on a queued job.
- `env()` is only called inside `config/`. Everything else reads `config()`,
  or it breaks once config is cached.
- Route model binding and named routes. Reach for the built-ins (policies,
  events, notifications, mail, storage, cache) before writing your own.
- Generate files with `php artisan make:*` and then edit them.

## Security

- Authorize every action with a policy or gate, through `authorize()`, the
  `can` middleware or `Gate::`. A route behind `auth` isn't authorized yet.
- Mass assignment only from validated data:
  `Model::create($request->validated())`, never `$request->all()`.
- Blade `{{ }}` for output. `{!! !!}` only for HTML that's already
  sanitized, with a comment saying where.
- Leave CSRF protection on for web routes.

## Database

- Every schema change is a new migration. Never edit one that has run
  anywhere but your machine.
- Add indexes and foreign keys in the migration that adds the column.
- Eager load with `with()` to stop N+1 queries, and keep
  `Model::preventLazyLoading()` on outside production if the app sets it.
- Factories and seeders for test data.
- `migrate:fresh`, `migrate:reset`, `db:wipe` and any rollback wipe data, so
  ask before running one, even locally.

## Tests and tooling

- Feature tests for endpoints, in whichever of PHPUnit or Pest the app
  already uses. Dusk for browser flows when the app has it.
- `php artisan test` before calling it done, plus `vendor/bin/pint --test`
  and Larastan when the project has them.
- Local sites are served by Valet at `http://<folder>.test`.
