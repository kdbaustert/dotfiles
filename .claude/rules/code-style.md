---
paths:
  - "**/*.php"
  - "**/*.swift"
  - "**/*.ts"
  - "**/*.tsx"
  - "**/*.js"
  - "**/*.jsx"
  - "**/*.mjs"
  - "**/*.cjs"
  - "**/*.vue"
  - "**/*.py"
  - "**/*.rb"
  - "**/*.go"
  - "**/*.rs"
  - "**/*.zig"
  - "**/*.c"
  - "**/*.h"
  - "**/*.cpp"
  - "**/*.hpp"
  - "**/*.m"
  - "**/*.mm"
  - "**/*.java"
  - "**/*.kt"
  - "**/*.lua"
  - "**/*.sh"
  - "**/*.bash"
  - "**/*.zsh"
  - "**/*.sql"
---

# Code style

Rules for code you write or change, condensed from *Clean Code* (Robert Martin)
and *Code Complete* (Steve McConnell). The full rule sets are under **Code
rules in full** in `~/.claude/REFERENCE.md`; read that section for a refactor,
a code review, concurrency work, or when a rule here is unclear. Where a
project's own `CLAUDE.md` or `AGENTS.md` disagrees, follow the project. If a
request conflicts with these rules, follow the request and say so.

## Priorities

When choices conflict, take the one that lowers defect risk, then the one
that reads more plainly, then the one with simpler control flow. No clever
tricks or fashionable idioms at the cost of clarity. Leave the code the task
changes cleaner than you found it, and mention problems outside it rather than
fixing them. Don't copy bad structure just because it sits nearby.

## Written by hand

Code should read like the developer who owns the file typed it. Don't write
AI-style code, the kind a reviewer picks out at a glance. If a teammate
reviewing the diff would guess it was generated, rewrite it. Copy the file's
own habits first: its idiom, naming, error handling, ordering and the helpers
it already uses.

AI-style code looks like this:

- Guards for what can't happen: a null check on a value the type guarantees,
  a `try`/`catch` that only logs and rethrows, a fallback default that hides a
  failure.
- A helper, wrapper, option or config value with one caller, or flexibility
  nobody asked for.
- The long way round where the language or the codebase has a short one, or a
  second copy of a helper the project already has.
- Names that say everything or nothing: `userDataResponseObject`, `result`,
  `data`, `helper`.
- Every function built to one template, with the same checks and logging
  whether the logic is hard or trivial. A developer spends lines where the
  logic is hard and none where it's obvious.
- Leftovers: unused imports and variables, commented-out code, debug output,
  a shim for code that's gone, a placeholder TODO.
- Banner and step comments ("// Step 1", "// --- Helpers ---"), and log
  messages with emoji or "Successfully".

## Names

- Reveal intent: purpose or behavior without needing a comment. Pronounceable
  and searchable, no type encodings or Hungarian notation, no abbreviations
  beyond domain or platform standards.
- One word per concept across the codebase. No synonyms for one operation, and
  no reusing a familiar word for a new meaning.
- Types and modules are nouns, functions are verbs. Domain names for domain
  concepts. No cute or private-joke names.

## Functions

- Small, one job, one level of abstraction, one reason to change. Order them
  top-down so the story comes before the details.
- Few parameters. No boolean flag parameters: split the function. Avoid output
  parameters.
- No hidden side effects. A function that answers a question doesn't change
  state.
- Guard clauses over deep nesting. Keep error handling apart from the main
  path.
- For a complex routine, sketch the steps in pseudocode first, then keep only
  the comments that still add intent.

## Data and control flow

- Smallest practical scope, deliberate initialization, one meaning per
  variable.
- Name magic numbers, units, bounds and sentinels. Enums for closed sets,
  booleans only for true binary meanings, and types that make invalid states
  hard to represent.
- Name complicated conditions as predicates. Prefer positive conditionals,
  keep the normal path easy to find, and give loops obvious start, end and
  update.
- Stable repeated branching becomes a table or map, never an inscrutable
  encoding. Remove dead branches and impossible paths.

## Errors and boundaries

- Validate input at trust boundaries. Assertions catch programmer mistakes,
  validation catches external input, domain errors carry expected failures.
- Never swallow an error or carry on from impossible state. Errors hold enough
  context to diagnose and are handled at the level that can act on them.
- Don't return or pass null where the language offers optionals, empty objects
  or exceptions. Make cleanup and shutdown paths correct and visible.
- Wrap unstable third-party APIs behind a narrow local interface.

## Classes and modules

- One responsibility, high cohesion, and a small public surface that's hard to
  misuse. Hide representation and expose behavior.
- Composition over inheritance unless inheritance is plainly simpler.
- Don't mix persistence, formatting, business logic and integration in one
  module. Construction and wiring live apart from ordinary behavior.

## Comments

- Fix the name or structure first. Comment only what code can't say: intent,
  the reason for a surprising decision, a warning, a contract, an external
  quirk, a license.
- Remove redundant, stale or misleading comments in code you change. No
  line-by-line narration, and no TODO unless it's specific and actionable.
- Write them the way a teammate types them by hand: lead with the point, name
  the real table, limit or ticket, and match the file's tone and density. No
  "This function...", no change history ("Updated to", "Fixed bug where"), no
  marketing words, em dashes, emoji or markdown emphasis. The tells in
  `~/.claude/rules/human-writing.md` apply to comments too.

```
// Bad:  This function is responsible for robustly retrieving the user's orders.
// Good: Skips archived orders; the nightly export reads those separately.
```

Docblocks follow the same rule: write each one the way the developer who owns
the file would type it by hand, and if a teammate would spot it as generated,
rewrite it. Generated docblocks look like this:

- Every tag gets a full sentence, and they all match in length and rhythm,
  even when the type already says it all.
- The summary opens with "This method", "Helper that", "Handles" or
  "Retrieves and returns", or just reads the name back as a sentence.
- The body walks through the parameters in prose, then the `@param` lines
  repeat it.
- Hedges or praise ("safely", "efficiently", "gracefully") that the code
  doesn't back up.

Shape:

- Copy the file's format first: tag set and order, alignment, summary mood and
  punctuation. A project standard (WordPress, PSR-5, Google style) wins.
- The summary says what the caller gets or what changes, as briefly as stays
  true. Add a body only for a side effect, an ordering requirement, a cost or
  a reason.
- Tags carry what the signature can't: precise types (`list<Order>`, `?User`,
  `array<string, int>`), units, accepted values, what null or empty means.
  Drop a description that repeats the name ("The user ID."), and a tag the
  native type already covers unless the project requires it. TypeScript JSDoc
  has no `{type}`.
- `@throws` only for what actually escapes, with when. No `@author`, `@since`,
  dates or history unless the project uses them.
- Update it in the same edit as the signature. Don't claim thread-safe,
  idempotent or O(1) unless you checked.

```php
/**
 * This method is responsible for retrieving the orders for the given user.
 *
 * @param int $userId The user ID.
 * @return array Returns an array of orders.
 */

/**
 * Returns the customer's open orders, newest first.
 *
 * @param int $userId
 * @return list<Order> empty when the customer has none
 */
```

## Tests

- Tests are production code: readable, deterministic, isolated, fast,
  self-checking, one idea each.
- A behavior change gets a test. A bug fix gets one that would have caught the
  bug. Cover normal, boundary and invalid inputs.
- A flaky, skipped or ignored test is an open question, not a pass.

## Change process

Understand the behavior, find the simplest correct change, keep edits local and
build in small steps you can verify. Keep refactoring separate from behavior
changes when that makes review easier. Debug by reproducing, isolating,
explaining, fixing and verifying, and fix the root cause. Add concurrency, an
optimization or a new dependency only with evidence it pays for itself.

## Before finishing

Read the diff: names reveal intent, functions are small, control flow is plain,
boundaries are defended, nothing is newly duplicated, comments earn their
place, style matches the codebase, nothing reads as generated, and complexity
went down or held level.
Then say what changed, what checks ran, and any risk left open.
