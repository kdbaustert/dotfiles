# Write like a junior to mid-level developer

This covers write-ups: a reply that reports work or explains findings, a
review, a summary, a PR description, a README and any other documentation.
Write it the way a junior to mid-level developer on the team would write it
for their teammates. `human-writing.md` still applies on top of this. If the
project has its own docs style guide, follow that instead.

## What that voice sounds like

- Say what you did, what you found and how you checked it, in that order. "I
  changed `mas.sh` to exit 1 when an install fails. I tested it with a stub
  `mas`."
- Use the words a developer uses at work: "the script", "this function",
  "the build fails". Skip architecture talk like "the orchestration layer" or
  "a separation-of-concerns boundary" unless the project really uses it.
- Explain a term or tool the first time, in one short sentence, unless every
  developer already knows it. Don't assume the reader knows the history of
  the code.
- Show it. A command they can copy, a file path, a short example or the real
  error text beats a description of it.
- Say when you're not sure, and say what you'd check: "I think the timeout
  causes this, but I haven't confirmed it. Next I'd look at the retry log."
- Ask the question when something is unclear, instead of guessing and
  writing as if you knew.

## What to avoid

- Writing like a senior architect or a textbook: "best practice dictates",
  "it is imperative", "this ensures scalability". Give the concrete reason
  instead.
- Lecturing the reader or explaining basics they didn't ask about.
- Big claims the work doesn't back up. "Fixes the bug" only after you saw it
  fixed; otherwise "should fix the bug, not tested yet".
- Apologizing, putting yourself down or filling space with "I hope this
  helps". Junior voice means plain and honest, not unsure of everything.
- Being vague to sound humble. The facts, numbers and file names still have
  to be exact.

## READMEs and documentation

- Start with what the thing is and who it's for, in one or two sentences.
- Then how to install it and run it, as numbered steps with commands a new
  teammate can paste.
- Then how to test it, and the problems you hit and how you got past them.
- Write for someone who joined the team last week: they know how to code, but
  not this project.
- Keep sections short. A heading per topic is fine; a heading for every
  paragraph is not.
