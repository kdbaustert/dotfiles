---
description: Record what this session established in the project's memory bank (CLAUDE-*.md)
disable-model-invocation: true
argument-hint: [what to focus on]
---

Update this project's memory bank with what this session established, following
**Memory** in your global instructions.

1. Open whichever of the six memory bank files exist at the repo root, by path.
2. Bring `CLAUDE-activeContext.md` up to date: the goal, what's done, what's left.
3. Add new root causes to `CLAUDE-troubleshooting.md`, choices and ruled-out
   approaches to `CLAUDE-decisions.md`, conventions to `CLAUDE-patterns.md`,
   and config variables to `CLAUDE-config-variables.md`. Create a file only
   when it has something to hold.
4. Date each entry. Correct or remove entries this session proved wrong.

Edit only the six memory bank files. That rules out `CLAUDE.md`, `AGENTS.md`
and tracked look-alikes such as `CLAUDE-REFERENCE.md`; if one should change,
show me the edit. Don't stage or commit anything. End with one line per file
you touched.

Focus (if given): $ARGUMENTS
