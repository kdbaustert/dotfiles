---
paths:
  - "**/artisan"
  - "**/bootstrap/app.php"
  - "**/app/Http/**"
  - "**/app/Models/**"
  - "**/app/Providers/**"
  - "**/app/Jobs/**"
  - "**/app/Policies/**"
  - "**/app/Actions/**"
  - "**/routes/*.php"
  - "**/database/migrations/**"
  - "**/database/factories/**"
  - "**/database/seeders/**"
  - "**/*.blade.php"
---

# Laravel

For Laravel apps and packages. It builds on `php.md`, and where the two
disagree this file wins.

## Version

Read the installed Laravel version from `composer.lock` and write for that
version's docs. Directory layout and bootstrapping changed in Laravel 11, so
copy the app's own structure rather than an older tutorial's: middleware,
exceptions and routing live in `bootstrap/app.php` and the schedule in
`routes/console.php` when the app has no `Kernel.php`. If the project
requires `laravel/boost`, use its tools for docs, routes, schema and logs
before guessing. Check `composer.json` for Livewire, Inertia, Filament or
Sanctum before choosing how to build something, and use what's there.

## Naming

Laravel's conventions, unless the app already does otherwise:

- Models are singular `StudlyCase` (`OrderItem`), tables plural `snake_case`
  (`order_items`), columns `snake_case`, foreign keys `order_id`.
- Pivot tables join the two singular names in alphabetical order:
  `product_tag`.
- Controllers are singular with a `Controller` suffix: `OrderController`.
  Resource controllers stick to the seven resource actions; anything else
  gets its own invokable controller.
- URLs are plural kebab-case (`/order-items`), route names dot-separated
  snake case (`order_items.index`), route parameters camelCase.
- Methods and variables `camelCase`, config and lang keys `snake_case`,
  events in the past tense (`OrderShipped`), jobs and listeners as verbs
  (`SendInvoice`).
- Relationship methods read as what they return: `author()` for
  `belongsTo`, `comments()` for `hasMany`.

## Structure

- Thin controllers. Validation goes in FormRequest classes, business logic in
  action or service classes.
- Inject dependencies through the constructor or the method signature. Facades
  are fine where the app already uses them; don't mix both styles in one
  class.
- Eloquent and the query builder first. Raw SQL only when they can't express
  it, and always with bindings.
- Every model declares its relationships, `casts` and `$fillable`. Never
  `$guarded = []`. Put sensitive columns (passwords, tokens) in `$hidden`.
  Cast enums, dates and JSON columns rather than converting by hand.
- Query scopes for filters the app repeats. Accessors and mutators through
  `Attribute::make()` when the version supports it.
- API Resources shape JSON responses. Never return a model straight from an
  API route.
- Slow work (mail, third-party calls, imports) goes on a queued job.
- `env()` is only called inside `config/`. Everything else reads `config()`,
  or it breaks once config is cached.
- Route model binding and named routes. Reach for the built-ins (policies,
  events, notifications, mail, storage, cache, collections, `Str` and `Arr`)
  before writing your own.
- Generate files with `php artisan make:*` and then edit them.
- Users see strings through `__()` and the `lang/` files when the app
  already translates. Otherwise match what's there.

## Security

- Authorize every action with a policy or gate, through `authorize()`, the
  `can` middleware or `Gate::`. A route behind `auth` isn't authorized yet.
- Mass assignment only from validated data:
  `Model::create($request->validated())`, never `$request->all()`.
- Validation rules as arrays, and `Rule::in()` or an enum rule for closed
  sets. `exists:` and `unique:` rules scope to the tenant or owner when the
  app has one.
- Blade `{{ }}` for output. `{!! !!}` only for HTML that's already
  sanitized, with a comment saying where.
- Leave CSRF protection on for web routes, and put `@csrf` in every form.
- `whereRaw()`, `orderByRaw()` and `DB::raw()` take bindings, never
  interpolated input. Column names from a request go through an allowlist.
- `Hash::make()` for passwords, `Crypt` for data you need back, signed URLs
  for links that act without a login.
- Rate limit login, password reset and public API routes with `throttle` or
  `RateLimiter`.
- Uploads go through `Storage` disks with validated `mimes` and `max` rules.
  Private files go on a private disk and get served through a controller or
  temporary URL.

## Database

- Every schema change is a new migration. Never edit one that has run
  anywhere but your machine.
- Add indexes and foreign keys in the migration that adds the column, with
  `constrained()` and a deliberate `onDelete` choice.
- Every migration has a working `down()`, unless the project leaves them out.
- Eager load with `with()` to stop N+1 queries, and keep
  `Model::preventLazyLoading()` on outside production if the app sets it.
- Select only the columns you need on large tables. `chunkById()` or `lazy()`
  for big result sets, `paginate()` for lists a user sees.
- Wrap multi-step writes in `DB::transaction()`. Events, jobs and mail
  triggered inside one use `afterCommit` so they don't fire on a rollback.
- Factories and seeders for test data.
- `migrate:fresh`, `migrate:reset`, `db:wipe` and any rollback wipe data, so
  ask before running one, even locally.

## Queues

- Jobs are safe to run twice. Set `$tries` and `$backoff`, and use
  `ShouldBeUnique` or `WithoutOverlapping` when two copies would clash.
- Pass IDs or models (which serialize by key), not big payloads.
- Handle failure in `failed()` rather than swallowing exceptions in `handle()`.

## Tests and tooling

- Feature tests for endpoints, in whichever of PHPUnit or Pest the app
  already uses. Dusk for browser flows when the app has it.
- `RefreshDatabase` (or whatever trait the suite already uses), factories
  with states, and the fakes (`Http::fake()`, `Queue::fake()`,
  `Mail::fake()`, `Storage::fake()`, `Event::fake()`) instead of real
  services. A test never calls a real third-party API.
- Test the authorization failure as well as the happy path: a guest and a
  user without permission both get rejected.
- `php artisan test` before calling it done, plus `vendor/bin/pint --test`
  and Larastan when the project has them.
- Local sites are served by Valet at `http://<folder>.test`.
