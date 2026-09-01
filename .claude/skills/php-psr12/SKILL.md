---
name: php-psr12
description: Write and verify PHP against the PSR-12 coding standard (and PSR-1, which it extends). Use whenever writing, editing or reviewing PHP — new classes, methods, controllers, models — and whenever the user invokes /php-psr12 or asks about PHP code style, formatting, brace placement, indentation, visibility keywords, or "does this follow PSR-12". Also use before finishing a PHP change, to check the files that change touched.
---

# PHP PSR-12

PSR-12 is a layout standard: indentation, braces, spacing, visibility, casing. It
extends PSR-1 (file structure and naming), so both are covered here, and it
replaces PSR-2 — every PSR-2 rule survives verbatim, plus the PHP 7+ constructs
PSR-2 was written too early to mention: `declare`, return types, nullable types,
constant visibility, operator spacing. Getting it right while writing costs
nothing; retrofitting it costs a diff nobody can review.

## Scope: only the files this change touched

**Never run the fixer across the tree.** Not `php-cs-fixer fix .`, not on a whole
directory, not "while I'm here."

This is not caution for its own sake — it was measured. In `~/Development/cnc-claims`
there are ~16,500 non-vendor PHP files, and a 300-file sample says the existing code
disagrees with PSR-12 almost everywhere it can:

| | Conforming | Violating |
| --- | --- | --- |
| Class brace on its own line | 29 | **294** |
| Method brace on its own line | 71 | **364** |
| Methods with explicit visibility | — | **25 without** |

Those three were counted against PSR-2, and they carry over unchanged because
PSR-12 inherits all three rules word for word. The count is therefore a floor, not
an estimate: PSR-12 is a strict superset, so it also flags operator spacing, import
grouping and cast casing that nobody has measured yet.

Indentation is the exception: the tree is already 4-space, which PSR-12 agrees with.

So a repo-wide fix would rewrite the brace placement of essentially every class and
method in the codebase, burying whatever actually changed and putting 16k files up
for retest. Format what the current change already touches, and leave the rest
alone. If the surrounding file is non-conforming, match PSR-12 in the lines you add
and say so — don't reformat the file around them.

## Writing it correctly the first time

The point of this section is to avoid the write-then-fix round trip. The fixer is
the check, not the author.

**Files.** Open with `<?php`, on its own line with nothing else on it. In a file
containing only PHP, **omit the closing `?>`** — a stray one leaks whitespace into
output. UTF-8 without BOM, LF endings, one final newline, no trailing whitespace,
no more than one statement per line. A file either declares symbols (classes,
functions, constants) or has side effects, not both.

**Header order.** PSR-12 fixes the order of everything above the first line of real
code, each block separated by exactly one blank line, and any block that is empty is
omitted entirely: opening tag, file docblock, `declare` statements, `namespace`,
`use` class imports, `use function` imports, `use const` imports, then the code.

**Indentation.** 4 spaces. Never tabs, never a mix. Line length 120 (PSR-12 calls
this a soft limit; treat it as the limit, which is also what the global PHP style
rule says).

**Namespace and imports.** One `use` per declaration, never with a leading
backslash, and compound namespaces never deeper than two levels. A `declare` has
no spaces inside it — `declare(strict_types=1);` exactly.

```php
<?php

declare(strict_types=1);

namespace App\Areas\Claims;

use App\Core\Controller;
use App\Core\Request;

use function App\Support\money;

class ClaimController extends Controller
{
```

**Class and method braces go on their own line.** This is the rule the existing
codebase breaks most often, so it is the one to be deliberate about. `extends` and
`implements` stay on the class line; a long `implements` list may be split one
interface per line, in which case the closing brace of the declaration still gets
its own line.

```php
class ClaimController extends Controller implements Auditable
{
    public function show(int $claimId): Response
    {
        // ...
    }
}
```

**Traits are imported one per `use`,** on the line immediately after the class's
opening brace, with no blank line between the brace and the first one.

```php
class ClaimReport
{
    use Cacheable;
    use Loggable;

    public function build(): string
```

**Visibility is mandatory** on every property, every method **and every class
constant** — the constant half is the PSR-12 addition, and it applies here because
it needs PHP 7.1+ and the target is 8.1. No bare `function foo()`, no `var`, one
property per statement. `abstract` and `final` come *before* the visibility;
`static` comes *after* it.

```php
private const MAX_ATTEMPTS = 3;

abstract protected function build(): void;
public static function fromArray(array $row): self
```

**Types.** Use the short scalar keywords — `bool`, `int`, `float`, `string`, never
`boolean`, `integer`, `double` or `real`. A nullable type has no space after the
`?`. A return type's colon hugs the closing parenthesis and takes one space after
it. A typed property has one space between the type and the name. Casts are
lowercase with no spaces inside the parentheses.

```php
private ?string $reference = null;

public function find(?int $claimId): ?Claim
{
    return $this->rows[(int) $claimId] ?? null;
}
```

**Control-structure braces go on the *same* line** — the opposite of classes and
methods, which is the part people get backwards. The closing brace and its
continuation keyword hug:

```php
if ($claim->isOpen()) {
    $this->notify($claim);
} elseif ($claim->isPending()) {
    $this->queue($claim);
} else {
    $this->archive($claim);
}
```

Use `elseif`, never `else if`. One space after a control keyword; **no** space
between a function or method name and its `(`. No space just inside parentheses.

```php
if ($count > 0) {        // one space after `if`
    $this->render($view); // no space after `render`
}
```

A condition split across lines indents once, keeps its boolean operators
consistently at the start of every line or consistently at the end — not a mix —
and puts the closing `)` and the `{` together on their own line:

```php
if (
    $claim->isOpen()
    && $claim->hasHandler()
) {
    $this->notify($claim);
}
```

**Operators.** Binary operators — arithmetic, comparison, assignment, logical,
concatenation, `instanceof` — take at least one space on each side. Ternaries space
both `?` and `:`, except `?:` which stays closed up. Unary `++`/`--` and `!` touch
their operand.

```php
$total = $net + $vat;
$label = $claim->isOpen() ? "open" : "closed";
$name = $handler ?: "unassigned";
$attempts++;
```

**Closures** take a space after `function` and a space either side of `use`; the
opening brace stays on the same line. If both a `use` list and a return type are
present, the colon hugs the `use` list's closing parenthesis.

```php
$total = array_reduce($claims, function (int $carry, Claim $claim) use ($rate): int {
    return $carry + $claim->value($rate);
}, 0);
```

**Casing.** PHP keywords lowercase, including `true`, `false` and `null`, and
`static`/`self`/`parent` in static references. Class names `StudlyCaps`, method
names `camelCase`, class constants `UPPER_SNAKE_CASE`.

**switch.** `case` indents once from `switch`; the body and `break` indent once
from `case`. Mark deliberate fall-through with a `// no break` comment.

```php
switch ($status) {
    case "open":
        $this->open();
        break;
    case "closed":
        // no break
    case "void":
        $this->close();
        break;
}
```

**Long argument lists** split one argument per line, starting on the line after
the `(`, with the closing `)` and the `{` together on their own line — and the
return type, when there is one, sitting between them:

```php
public function record(
    int $claimId,
    string $event,
    array $payload
): void {
    // ...
}
```

## Checking a change

Both commands take the files the change touched — staged, unstaged and untracked —
and nothing else. `--dry-run` reports without writing; drop it to apply.

Check:

```sh
{ git diff --name-only --diff-filter=ACMR HEAD -- '*.php'
  git ls-files -o --exclude-standard -- '*.php'; } | sort -u | tr '\n' '\0' | \
  xargs -0 -r php-cs-fixer fix \
    --config ~/.claude/skills/php-psr12/php-cs-fixer.psr12.php \
    --dry-run --diff --using-cache=no
```

Apply, then show what moved:

```sh
{ git diff --name-only --diff-filter=ACMR HEAD -- '*.php'
  git ls-files -o --exclude-standard -- '*.php'; } | sort -u | tr '\n' '\0' | \
  xargs -0 -r php-cs-fixer fix \
    --config ~/.claude/skills/php-psr12/php-cs-fixer.psr12.php \
    --using-cache=no
```

The `--config` is not optional decoration: php-cs-fixer refuses more than one path
without one ("For multiple paths config parameter is required"), and reviewing a
change is always multi-path. `xargs -r` is what stops an empty file list from
turning into a run over the whole working directory — never remove it.

Report the fixer's own output when it finds something. Don't paraphrase a diff.

Two of the rules `@PSR12` adds over `@PSR2` move code rather than whitespace, so
know them before reading a diff: `ordered_imports` regroups `use` into class, then
function, then const blocks (it does **not** alphabetise — the set pins
`sort_algorithm` to `none`), and `ordered_class_elements` is scoped to `use_trait`
only, so it hoists trait imports to the top of the class and reorders nothing else.
Neither touches method order.

## What PSR-12 does not decide

PSR-12 is silent on quote style and trailing commas, so it does **not** override the
PHP rules in the global `CLAUDE.md`: double quotes, no trailing commas, PHP 8.1
target. Those still apply. It is a layout standard, not a house style — where it
says nothing, the repo and then the global rules decide.

It also does not decide whether to *have* `declare(strict_types=1)`, only how to
format and place one that exists — the fixer rule that would add it lives in
`@PSR12:risky`, which this config deliberately does not use. Same for docblocks:
PSR-12 says nothing about whether a method needs one or what goes in it.

## The standard's own succession

PHP-FIG deprecated PSR-2 in 2019 in favour of PSR-12, which PER Coding Style has
since superseded in turn. This skill implements PSR-12 because that is what was
asked for, and php-cs-fixer still ships it as a first-class ruleset (verified
against 3.95.24: `@PSR2`, `@PSR12` and `@PER-CS` up to `@PER-CS3.0` are all
present). If PER's additions — trailing commas in multiline lists chief among them,
which the global PHP rules currently forbid — start to matter,
`php-cs-fixer.psr12.php` isolates the choice on one line: `"@PSR12"` becomes
`"@PER-CS3.0"` and nothing else changes.
