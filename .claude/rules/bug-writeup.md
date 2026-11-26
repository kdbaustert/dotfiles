# Writing up a bug and its fix

Use this when you're asked to document an issue or bug you found, or the fix
for it: in a reply, a Jira ticket, a PR description, a commit message or the
memory bank. Write it the way a junior to mid-level developer would write it
for the team, as `developer-voice.md` describes. Keep it simple and short.

Use these parts, in this order. Skip a part you have nothing for.

1. **Problem**: what goes wrong, in one or two sentences, with the real error
   text or output. "`mas.sh` exits 0 even when an install fails."
2. **Steps to reproduce**: numbered steps or a command someone can paste.
3. **Cause**: what's wrong in the code, with `file:line`. If you haven't
   confirmed it, say "I think" and say what would confirm it.
4. **Fix**: what you changed and where, in plain words. Name the files.
5. **How I checked it**: the command you ran and what it showed. If you
   didn't test it, write "Not tested yet".

Keep it plain:

- One short paragraph or a few bullets per part. No extra headings.
- Facts only. No blame, no story of every step you tried, unless a ruled-out
  cause will save the next person time.
- If the bug isn't fixed yet, stop after **Cause** and say what's left.
