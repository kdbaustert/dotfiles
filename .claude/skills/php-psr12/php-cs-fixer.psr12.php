<?php

/**
 * PSR-12 ruleset for the php-psr12 skill.
 *
 * This config exists at all because php-cs-fixer *requires* one the moment you
 * hand it more than a single path: `php-cs-fixer fix a.php b.php --rules=@PSR12`
 * dies with "For multiple paths config parameter is required." The whole point
 * of the skill is to format the handful of files a change touched, which is
 * always a multi-path invocation, so `--rules` alone was never going to work.
 *
 * It lives here, in the skill directory, rather than being written into the
 * project being worked on. Dropping a .php-cs-fixer.dist.php into cnc-claims
 * would be a tracked file committing that repo to a standard ~90% of its
 * existing classes violate (measured: 294 of 323 sampled class declarations put
 * the opening brace on the same line, which PSR-12 forbids exactly as PSR-2
 * did). Keeping the config out here means the standard applies to what we write
 * without retroactively condemning 16k files nobody asked us to touch.
 *
 * The ruleset is deliberately one line so the neighbouring standards are a
 * one-word edit. PHP-FIG deprecated PSR-2 in 2019 in favour of PSR-12, which
 * PER Coding Style has since superseded in turn; php-cs-fixer ships all of them
 * (verified against 3.95.24: `@PSR2`, `@PSR12`, `@PER-CS3.0`). PSR-12 is the
 * newest of those whose rules the global PHP style already agrees with — PER
 * mandates a trailing comma in every multiline list, which the global CLAUDE.md
 * forbids, so moving up is a decision about house style and not just recency.
 *
 * The plain `@PSR12` set is chosen over `@PSR12:risky` on purpose: the risky
 * half is mostly `declare_strict_types`, which inserts a declaration that
 * changes how every call into the file coerces its arguments. That is a
 * behaviour change wearing a formatter's clothes, and it belongs in a commit of
 * its own.
 */

$finder = PhpCsFixer\Finder::create()
    ->in(getcwd())
    ->exclude(["vendor", "node_modules", "tmp"])
    ->name("*.php");

/*
 * setIndent is explicit rather than left to the default because the deployed
 * ~/.editorconfig sets `indent_size = 2` for `[*]` with no `[*.php]` override,
 * and cnc-claims has no .editorconfig of its own — so an editorconfig-aware
 * tool walking up from a PHP file there lands on the 2-space rule. PSR-12
 * mandates 4, and the tree is already 4 in practice. Stating it here means the
 * fixer wins that disagreement regardless of what the editor believes.
 *
 * setRiskyAllowed stays false: risky fixers change behaviour, not just layout,
 * and a formatting pass is not the place to find out which.
 */
return (new PhpCsFixer\Config())
    ->setRules(["@PSR12" => true])
    ->setIndent("    ")
    ->setLineEnding("\n")
    ->setRiskyAllowed(false)
    ->setFinder($finder);
