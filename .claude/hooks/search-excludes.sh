#!/usr/bin/env bash
#==============================================================================
#  Claude Code PreToolUse hook — keep widened searches out of noise folders
#==============================================================================
# Wired from ~/.claude/settings.json, beside the atuin PreToolUse entry:
#
#   { "matcher": "Bash", "hooks": [{ "type": "command",
#     "command": "$HOME/.claude/hooks/search-excludes.sh" }] }
#
# settings.json is not tracked (see notify.sh's header for why), so those lines
# are the manual step on a new machine; the repo CLAUDE.md repeats them.
#
# CLAUDE.md tells Claude never to search the eight folders below and to name
# them on any `rg`/`fd` that is widened past the ignore files. This is the
# backstop for when it forgets. Only the widened case is checked: a plain `rg`
# already honours .gitignore, which covers these folders in most repos, and
# blocking every search would cost more turns than the noise it saves.
#
# Exit 2 is how a PreToolUse hook blocks a call; stderr goes back to Claude as
# the reason, so it can rerun the search with the glob. Every other path exits
# 0, including a payload this script can't read: a broken hook must never stop
# Claude running commands.
#
# It is a string check, not a shell parser. A widened search behind a variable
# or an alias gets through, and so does `rg -uu` written inside a quoted
# pattern. Good enough for a backstop; REFERENCE.md has the reasoning.

folders=(node_modules vendor build out public storage logs tmp)

input=$(cat)
command=$(jq -r '.tool_input.command // empty' <<<"$input" 2>/dev/null)
[[ -n $command ]] || exit 0

folder_alternation=$(
  IFS='|'
  echo "${folders[*]}"
)

# True when one pipeline segment runs rg or fd with the ignore files turned
# off. rg's -I means --no-filename, so -I only counts for fd.
#
# @param $1 one segment of the command, split on | ; &
# @return 0 if the segment is a widened search, 1 otherwise
is_widened_search() {
  local segment=$1
  local rg_widen='[[:space:]]-[a-zA-Z]*u[a-zA-Z]*([[:space:]]|$)'
  local fd_widen='[[:space:]]-[a-zA-Z]*[uI][a-zA-Z]*([[:space:]]|$)'
  local long_widen='[[:space:]]--(no-ignore[a-z-]*|unrestricted)([[:space:]=]|$)'

  if [[ $segment =~ (^|[[:space:]])rg[[:space:]] ]]; then
    [[ $segment =~ $rg_widen || $segment =~ $long_widen ]]
    return
  fi

  if [[ $segment =~ (^|[[:space:]])fd[[:space:]] ]]; then
    [[ $segment =~ $fd_widen || $segment =~ $long_widen ]]
    return
  fi

  return 1
}

# A search aimed inside one of the folders (node_modules/pkg, ./vendor/x) is
# the exception the rule allows.
#
# @param $1 one segment of the command
# @return 0 if the segment names a path that starts in one of the folders
targets_a_folder() {
  [[ $1 =~ (^|[[:space:]\'\"/])(\./)?($folder_alternation)/ ]]
}

widened=0
while IFS= read -r segment; do
  is_widened_search "$segment" || continue
  targets_a_folder "$segment" && exit 0
  widened=1
done < <(tr '|;&' '\n' <<<"$command")

((widened)) || exit 0

# Each name has to appear as a whole word, so "out" isn't satisfied by
# "--stdout" or "output".
missing=()
for folder in "${folders[@]}"; do
  [[ $command =~ (^|[^[:alnum:]_-])$folder([^[:alnum:]_-]|$) ]] || missing+=("$folder")
done

((${#missing[@]})) || exit 0

glob="{$(
  IFS=','
  echo "${folders[*]}"
)}"
{
  echo "Widened search is missing excludes for: ${missing[*]}."
  echo "Add -g '!$glob' to rg, or -E '$glob' to fd."
  echo "If the task is about one of these folders, search that folder's path directly."
} >&2
exit 2
