#!/usr/bin/env bash
#==============================================================================
#  Claude Code PreToolUse hook: block the commands the rules say never to run
#==============================================================================
# Wired by settings.portable.json, which merge_claude_settings() in
# setup/lib.sh merges into ~/.claude/settings.json beside the other Bash
# PreToolUse hooks.
#
# The global CLAUDE.md and this repo's AGENTS.md say "never" about a handful of
# commands, and prose is the weakest way to hold that line: one long session or
# one harness default ("branch first on main") and the rule is gone. Each check
# below is one of those rules, named in its block message so Claude knows what
# to do instead:
#
#   git --no-verify, git commit -n           never skip hooks
#   commit.gpgsign=false, --no-gpg-sign      never disable signing
#   git config user.email|signingkey VALUE   no per-repo identity set by hand
#   git config --global (writes)             it rewrites the tracked .gitconfig
#   checkout -b, switch -c, branch NAME,     never create a branch
#     worktree add without an existing ref,
#     checkout/switch of a name only a
#     remote has (git creates it locally)
#   git merge / git pull of develop|staging  never merge integration branches
#     (FETCH_HEAD included)
#   push --force without both lease flags    a confirmed force push uses
#                                              --force-with-lease --force-if-includes
#   nix profile install/add, nix-env -i      Nix is per-project only
#   abbr add/erase/rename/import, iris       they rewrite tracked dotfiles
#     setup/uninstall
#   sed -i / perl -i on a symlink            replaces the link with a copy
#   running this repo's install.sh           it changes the system
#
# permissions.deny can't do this job. It matches a command by prefix, so it
# can't see `--no-verify` at the end of a commit, a branch name after `git -C
# path`, or whether a sed target is a symlink, and its refusal carries no
# reason. One hook with a reason per rule covers all of these.
#
# The way out is deliberate: a `! <command>` the user types runs in their
# shell, not through the Bash tool, so no PreToolUse hook sees it. Every block
# message says so, which keeps the hook from ever being the reason something
# the user asked for can't happen.
#
# The command is parsed, not pattern-matched. shfmt (homebrew/Brewfile) turns
# it into a syntax tree with its zsh dialect, since the Bash tool runs zsh, and
# jq walks that tree for every simple command in source order. That is what
# keeps a commit message describing these rules (`-m "git config --global"`,
# a quoted heredoc) from reading as a command, and what finds the real
# commands inside $( ), backticks within double quotes, subshells, functions
# and control flow. Splitting the text with an awk state machine doesn't work:
# it can't see through any of the indirection below, and every fix to its
# quoting makes the next gap harder to close.
#
# Indirection is followed rather than ignored:
#   - `eval STRING` and `sh|bash|zsh|dash|ksh -c STRING` parse the string as a
#     command again, up to max_depth levels deep.
#   - A variable assigned a literal earlier in the command (`b=x; git branch
#     $b`) is substituted. One assigned two different values, or from a loop,
#     a $( ) or anything else only known when it runs, becomes a placeholder
#     byte, and a placeholder where a name belongs counts as a name: `git
#     branch $b` creates a branch whatever $b holds.
#   - Aliases and functions come from the Bash tool's shell snapshot, the
#     newest ${CLAUDE_CONFIG_DIR:-~/.claude}/shell-snapshots/snapshot-zsh-*.sh,
#     which is what that shell actually sources. An alias is expanded as text
#     with the call's arguments after it; a function's body is walked with $1..
#     and "$@" bound to them. Git aliases (`git config alias.nb 'checkout -b'`,
#     or one passed with -c) are expanded the same way, `!` shell aliases
#     included.
#   - `git checkout x` and `git switch x` create a local branch when only a
#     remote has x, so those check the repo's refs. `git merge FETCH_HEAD`
#     merges whatever the last fetch marked for merge, so it reads that file,
#     plus any `git fetch ... develop` earlier in the same command.
#   - A shell reading its script from stdin gets the heredoc or here-string
#     checked as a command; one fed by a pipe is blocked, since the pipe's
#     output is only known when it runs.
#
# What still gets through: a command whose name is only known when it runs
# (`$tool branch x` after `tool=$(which git)`), `eval "$x"` with x set at
# runtime, scripts run from a file, `find -exec`, `source <(...)`, a glob or
# loop variable naming a symlinked sed target, abbreviated long options
# (`--no-ver`), and functions or aliases defined in a file the command
# sources. When the command doesn't parse in
# either the zsh or bash dialect, it is blocked only if it names one of the
# guarded tools, with a request to rewrite it in plain syntax. Exit 2 blocks;
# every other path, including a missing shfmt or a payload this script can't
# read, exits 0, because a broken hook must never stop Claude running
# commands.

command -v shfmt >/dev/null || exit 0

{
  IFS= read -r -d '' command
  IFS= read -r -d '' cwd
} < <(jq -j '(.tool_input.command // ""), "\u0000", (.cwd // ""), "\u0000"' 2>/dev/null)
[[ -n $command ]] || exit 0
[[ -d $cwd ]] || cwd=$PWD

# The repo this script lives in, through the ~/.claude/hooks symlink, so the
# install.sh check needs no hard-coded checkout path.
repo=$(cd "$(dirname "$(realpath "${BASH_SOURCE[0]}")")/../.." && pwd)

# Stands in for any text only known when the command runs. Bash can carry it
# in a variable, jq in a string, and shfmt in a word, and no real argument
# contains it.
marker=$'\001'

# Stands in for $(git rev-parse --show-toplevel), which resolve_path answers
# from the tracked directory. The jq program makes the same token.
toplevel=$'\002toplevel'

# How deep eval, sh -c, aliases and functions may nest. Five is more nesting
# than any real alias chain in the snapshot. Past it, text Claude wrote is
# blocked, since letting it through would make six wrappers a way around every
# rule; the user's own snapshot code is let through. Recursion never reaches
# this: a function already being walked on the path is skipped.
max_depth=5

# Set by a `git fetch` of develop or staging, so a later `git merge
# FETCH_HEAD` in the same command counts as merging it.
fetched_integration=0

# Functions the command defines, one "name<TAB>tree JSON" line each, filled
# as walk_tree meets their definitions.
inline_functions=""

# Filled on first use by load_snapshot.
snapshot_loaded=0
snapshot=""
snapshot_aliases=""
snapshot_functions=""

# Emits a record per simple command ("call", its stdin, then its words) and per function
# definition ("function", its name and its tree as JSON), each @sh-quoted and
# NUL-terminated, in source order. Words are expanded the way the shell would
# where that's known from the text alone: quotes and backslashes removed,
# $HOME, variables assigned a literal earlier on, and the positional
# parameters when --arg known is "yes" (a function call, whose --args are its
# arguments). Anything else becomes the marker. `..` visits nodes in source
# order, so an assignment or a definition is seen before the commands after it.
read -r -d '' calls_program <<'JQ'
def marker: "\u0001";

# $(git rev-parse --show-toplevel) is how a command usually reaches its repo
# root (`cd "$(git rev-parse --show-toplevel)" && ./install.sh`), and the
# guard can answer it from the tracked directory, so it gets a token of its
# own rather than the marker.
def toplevel: "\u0002toplevel";

def toplevel_subst:
  (.Stmts | length) == 1
  and .Stmts[0].Cmd.Type == "CallExpr"
  and ([.Stmts[0].Cmd.Args[] | .Parts | if all(.[]; .Type == "Lit") then map(.Value) | join("") else null end]
       == ["git", "rev-parse", "--show-toplevel"]);

# Outside a function call nothing says what $1 or "$@" hold, and an empty
# guess would hide `f --no-verify` from a body that runs `git commit "$@"`.
def positional: if $known == "yes" then $ARGS.positional else [marker] end;

def unescape_bare: gsub("\\\\\n"; "") | gsub("\\\\(?<c>.)"; "\(.c)");
def unescape_double: gsub("\\\\\n"; "") | gsub("\\\\(?<c>[$`\"\\\\])"; "\(.c)");
def unescape_dollar:
  gsub("\\\\n"; "\n") | gsub("\\\\t"; "\t") | gsub("\\\\(?<c>['\"\\\\])"; "\(.c)");

# ${x:-y}, ${#x}, ${(f)x} and friends all compute something; only a bare $x
# or ${x} is looked up.
def plain_param: (keys - ["Type", "Param", "Short", "Dollar", "Rbrace", "Pos", "End"]) == [];

def param($vars):
  .Param.Value as $name
  | if plain_param | not then marker
    elif $name | test("^[1-9][0-9]*$") then positional[($name | tonumber) - 1] // marker
    elif $name == "@" or $name == "*" then positional | join(" ")
    elif $name == "HOME" then $ENV.HOME // marker
    else $vars[$name] // marker
    end;

def part($vars; $quoted):
  if .Type == "Lit" then .Value | if $quoted then unescape_double else unescape_bare end
  elif .Type == "SglQuoted" then if .Dollar then .Value | unescape_dollar else .Value end
  elif .Type == "DblQuoted" then [(.Parts // [])[] | part($vars; true)] | join("")
  elif .Type == "ParamExp" then param($vars)
  elif .Type == "CmdSubst" and toplevel_subst then toplevel
  else marker
  end;

def literal_number($word):
  ($word.Parts // []) as $parts
  | if ($parts | length) == 1 and $parts[0].Type == "Lit" and ($parts[0].Value | test("^[0-9]+$"))
    then $parts[0].Value | tonumber
    else null
    end;

# "$@" and "${@:N}" (or "${@:N:L}") are the expansions that make several
# words, or none, so a wrapper function passes its flags through intact. null
# when $part is anything else, or a slice computed at run time.
def arg_list($part):
  if $part.Type != "ParamExp" or $part.Param.Value != "@" then null
  elif (($part | keys) - ["Type", "Param", "Short", "Dollar", "Rbrace", "Pos", "End", "Slice"]) != [] then null
  elif $known != "yes" then [marker]
  elif $part.Slice == null then $ARGS.positional
  else literal_number($part.Slice.Offset) as $offset
    | (if $part.Slice.Length == null then -1 else literal_number($part.Slice.Length) end) as $length
    | if $offset == null or $offset == 0 or $length == null then null
      elif $length < 0 then $ARGS.positional[$offset - 1:]
      else $ARGS.positional[$offset - 1:$offset - 1 + $length]
      end
  end;

def only_part:
  if (.Parts | length) != 1 then null
  elif .Parts[0].Type == "DblQuoted" and (.Parts[0].Parts | length) == 1 then .Parts[0].Parts[0]
  else .Parts[0]
  end;

def words($vars):
  arg_list(only_part) as $list
  | if $list != null then $list[] else [(.Parts // [])[] | part($vars; false)] | join("") end;

# A second, different value means the shell's value depends on which branch
# ran, so it becomes the marker for good.
def assign($name; $value):
  .vars[$name] |= (if . == null or . == $value then $value else marker end);

def assign_node($node):
  .vars as $vars
  | if $node.Naked then .
    elif $node.Append or $node.Array or $node.Index then assign($node.Name.Value; marker)
    else assign($node.Name.Value; [($node.Value.Parts // [])[] | part($vars; false)] | join(""))
    end;

# What a command reads on stdin, for a shell that runs it as a script: "t"
# and the text of a heredoc or here-string, "f" and the path of a `<` file,
# "u" for a pipe whose output is only known when it runs, "" for none.
def stdin_source($vars):
  [(.Redirs // [])[] | select((.N.Value // "0") == "0")
    | if .Op == "<<" or .Op == "<<-" then "t" + ([(.Hdoc.Parts // [])[] | part($vars; true)] | join(""))
      elif .Op == "<<<" then "t" + ([(.Word.Parts // [])[] | part($vars; false)] | join(""))
      elif .Op == "<" then "f" + ([(.Word.Parts // [])[] | part($vars; false)] | join(""))
      else empty
      end]
  | last;

def is_stmt: .Type == null and has("Cmd");

# `..` yields a pipeline before its right-hand statement, and a statement
# before its command, so stdin is known by the time the command is reached.
# A redirect on the statement wins over the pipe, as it does in the shell.
reduce (.. | objects | select(.Type == "CallExpr" or .Type == "DeclClause" or .Type == "WordIter" or .Type == "FuncDecl" or .Type == "BinaryCmd" or is_stmt)) as $node
  ({vars: {}, calls: [], stdin: {}};
    .vars as $vars
    | if $node | is_stmt then
        ($node | stdin_source($vars)) as $source
        | if $source != null and $node.Cmd.Type == "CallExpr" then .stdin[$node.Cmd.Pos.Offset | tostring] = $source else . end
      elif $node.Type == "BinaryCmd" then
        if ($node.Op == "|" or $node.Op == "|&") and $node.Y.Cmd.Type == "CallExpr"
        then .stdin[$node.Y.Cmd.Pos.Offset | tostring] = "u"
        else .
        end
      elif $node.Type == "FuncDecl" then .calls += [["function", $node.Name.Value, ($node | tojson)]]
      elif $node.Type == "WordIter" then assign($node.Name.Value; marker)
      elif $node.Type == "DeclClause" then reduce ($node.Args // [])[] as $arg (.; assign_node($arg))
      elif ($node.Args // []) == [] then reduce ($node.Assigns // [])[] as $arg (.; assign_node($arg))
      else .calls += [["call", (.stdin[$node.Pos.Offset | tostring] // ""), ($node.Args[] | words($vars))]]
      end)
| .calls[]
| select(length > 2)
| @sh + "\u0000"
JQ

# Print the reason and the escape hatch, then block the call.
#
# @param $1 what was blocked and what to do instead
# @return never; exits 2
block() {
  {
    echo "Blocked: $1"
    echo "If the user explicitly asked for this exact command, ask them to run it as \`! <command>\`."
  } >&2
  exit 2
}

# Parse shell source and check every command in it. depth and expanded are
# locals here and read by the functions this calls, which is how a nested
# eval, alias or function knows how deep it sits and which aliases are already
# open on its path.
#
# @param $1 the shell source
# @param $2 how many levels of eval, sh -c, alias or function this is inside
# @param $3 "command" for text Claude wrote, "snapshot" for the user's own
#           alias definitions
# @param $4 the aliases already expanded on this path, space-separated
check_source() {
  local source=$1 depth=$2 origin=$3 expanded=$4
  local tree
  if ((depth > max_depth)); then
    [[ $origin == command ]] && block_too_deep
    return 0
  fi

  if ! tree=$(parse_source "$source"); then
    [[ $origin == command ]] && check_unparsed "$source"
    return 0
  fi
  walk_tree "$tree" no
}

# @return never; exits 2
block_too_deep() {
  block "This command nests eval, sh -c, aliases or functions more than $max_depth levels deep, past what the guard follows. Run the inner command directly."
}

# Check every command in a syntax tree, and remember the functions it defines
# so a later call can walk the body with its own arguments.
#
# @param $1 the tree as JSON: a whole file, or one function definition
# @param $2 "yes" when $@ from $3 on are the positional parameters, "no" when
#           they aren't known
# @param $@ from $3 on, the positional parameters
#
# A jq failure is a bug in the program above meeting a tree it didn't expect
# (an empty "" has no Parts, which stops it cold). Reading no records
# would wave the whole command through, so it falls back to the same rule as
# a command shfmt can't parse.
walk_tree() {
  local tree=$1 known=$2 record stdin
  local -a words records
  shift 2

  mapfile -d '' records < <(jq -j --arg known "$known" "$calls_program" --args -- "$@" <<<"$tree" 2>/dev/null)
  wait $! || check_unparsed "$command"

  for record in "${records[@]}"; do
    eval "words=($record)"
    if [[ ${words[0]} == function ]]; then
      inline_functions+=$'\n'"${words[1]}"$'\t'"${words[2]}"
    else
      stdin=${words[1]}
      check_call "${words[@]:2}"
    fi
  done
}

# zsh first, since that's the shell the Bash tool runs; bash catches the odd
# construct shfmt's zsh dialect rejects.
#
# @param $1 the shell source
# @return the syntax tree as JSON on stdout; non-zero if neither dialect parses it
parse_source() {
  shfmt -ln zsh --to-json <<<"$1" 2>/dev/null ||
    shfmt -ln bash --to-json <<<"$1" 2>/dev/null
}

# A command shfmt can't parse can't be checked, so one that mentions a guarded
# tool is sent back to be rewritten rather than let through unread.
#
# @param $1 the shell source
check_unparsed() {
  local guarded='(^|[^[:alnum:]_.-])(git|nix|nix-env|abbr|iris|sed|gsed|perl|eval|install\.sh)([^[:alnum:]_-]|$)'
  [[ $1 =~ $guarded ]] &&
    block "The guard couldn't parse this command, so the guard can't check its ${BASH_REMATCH[2]} call. Rewrite it in plain bash syntax."
  return 0
}

# One simple command: wrappers dropped, then checked as itself and as
# whatever it expands to.
#
# @param $@ the command's words
check_call() {
  local name wrapped=0
  local -a words
  skip_prefix "$@"
  ((${#words[@]})) || return 0
  name=${words[0]}

  # A command name only known when it runs can't be checked, except that one
  # ending in install.sh is almost certainly this repo's.
  if [[ $name == *"$marker"* ]]; then
    [[ ${name##*/} == install.sh ]] && check_install "$name"
    return 0
  fi

  case ${name##*/} in
    cd | pushd)
      change_directory "${words[1]-}"
      return 0
      ;;
    eval)
      check_source "${words[*]:1}" $((depth + 1)) "$origin" "$expanded"
      return 0
      ;;
    sh | bash | zsh | dash | ksh)
      check_shell "${words[@]:1}"
      return 0
      ;;
    source | .)
      check_install "${words[1]-}"
      return 0
      ;;
  esac

  check_command "${words[@]}"
  # zsh expands aliases and finds functions only in command position, so
  # `sudo gb` or `env gb` runs a program named gb, not the alias.
  ((wrapped)) && return 0
  check_alias "${words[@]}"
  check_function "${words[@]}"
}

# Drop what can sit in front of the real command: VAR=value assignments after
# env, and wrappers with their options (the options listed per wrapper take a
# value, which goes too). Keywords, braces and `!` never get here; the parser
# keeps them out of a command's words. `env -S STRING` splits STRING into the
# command itself, which is what eval does with it.
#
# @param $@ the words of one command
# @return the words from the real command on, in the caller's array `words`,
#         and 1 in the caller's `wrapped` when a wrapper other than zsh's
#         noglob and nocorrect stands in front of it
skip_prefix() {
  local -a all=("$@")
  local i=0 wrapper="" takes_value split

  while ((i < ${#all[@]})); do
    if [[ ${all[i]} =~ ^[A-Za-z_][A-Za-z0-9_]*= ]]; then
      i=$((i + 1))
      continue
    fi
    if [[ ${all[i]} == -- && -n $wrapper ]]; then
      i=$((i + 1))
      continue
    fi

    case ${all[i]} in
      env) takes_value='^-[uCSP]$' ;;
      sudo) takes_value='^-[ugChpUrt]$' ;;
      nice) takes_value='^-n$' ;;
      timeout) takes_value='^-[sk]$' ;;
      xargs) takes_value='^-[IJLnPRSsEd]$' ;;
      stdbuf) takes_value='^-[ioe]$' ;;
      watch) takes_value='^-n$' ;;
      arch) takes_value='^-[de]$' ;;
      command | builtin | exec | nohup | time | caffeinate | setsid | noglob | nocorrect) takes_value='^$' ;;
      *) break ;;
    esac
    wrapper=${all[i]}
    [[ $wrapper == noglob || $wrapper == nocorrect ]] || wrapped=1
    i=$((i + 1))

    while [[ ${all[i]-} == -* && ${all[i]} != -- ]]; do
      if [[ $wrapper == env && ${all[i]} =~ ^(-S|--split-string=?)(.*)$ ]]; then
        split=${BASH_REMATCH[2]}
        [[ -n $split ]] || { i=$((i + 1)); split=${all[i]-}; }
        words=(eval "$split" "${all[@]:i+1}")
        return 0
      fi
      [[ ${all[i]} =~ $takes_value ]] && i=$((i + 1))
      i=$((i + 1))
    done
    # timeout's first operand is the duration.
    [[ $wrapper == timeout ]] && i=$((i + 1))
  done

  words=("${all[@]:i}")
}

# `cd ~/dotfiles && ./install.sh` runs the repo's install.sh from anywhere, so
# later paths resolve against the new directory. A target only known at run
# time leaves the directory unknown, and relative paths after it unresolved.
#
# @param $1 the cd target, empty for $HOME
change_directory() {
  local target
  if ! target=$(resolve_path "${1:-$HOME}"); then
    cwd=""
  elif [[ -d $target ]]; then
    cwd=$target
  fi
}

# Expand a leading ~, then anchor a relative path at the tracked cwd, so a
# word can be tested as a file.
#
# @param $1 one word of the command
# @return the absolute path on stdout; non-zero if it can't be known
resolve_path() {
  local word=$1 root
  [[ $word == *"$marker"* ]] && return 1
  if [[ $word == "$toplevel"* ]]; then
    [[ -n $cwd ]] || return 1
    root=$(git -C "$cwd" rev-parse --show-toplevel 2>/dev/null) || return 1
    word=$root${word#"$toplevel"}
  fi
  word=${word/#\~/$HOME}
  if [[ $word != /* ]]; then
    [[ -n $cwd ]] || return 1
    word="$cwd/$word"
  fi
  echo "$word"
}

# Quote words so they parse back as the same words. A word holding the marker
# goes in as a parameter the walk can't know, so it comes out as the marker
# again; one starting with the toplevel token goes back in as the command
# substitution it came from.
#
# @param $@ words
# @return the quoted words, space-separated, on stdout
quote_words() {
  local word
  local -a quoted=()
  for word in "$@"; do
    if [[ $word == *"$marker"* ]]; then
      # shellcheck disable=SC2016 # the parameter is for the parser, not bash
      quoted+=('"${__guard_unknown}"')
    elif [[ $word == "$toplevel"* ]]; then
      # shellcheck disable=SC2016 # the substitution is for the parser, not bash
      quoted+=('"$(git rev-parse --show-toplevel)"'"$(printf '%q' "${word#"$toplevel"}")")
    else
      quoted+=("$(printf '%q' "$word")")
    fi
  done
  echo "${quoted[*]}"
}

# `sh -c STRING` runs STRING as a command; `sh FILE` runs a script, which
# matters only when it is install.sh; with neither, or with -s, the shell runs
# what arrives on stdin. A heredoc or here-string is checked like -c, a `<`
# file like FILE. A pipe is blocked: whatever feeds it is only known when it
# runs, and `printf 'git branch x' | bash` would otherwise walk past every
# rule. A parse check (bash -n) is how REFERENCE.md says to test install.sh,
# so it stays allowed.
#
# @param $@ the arguments after the shell's name; stdin is the caller's
check_shell() {
  local run_string=0 syntax_only=0 read_stdin=0

  while (($#)); do
    case $1 in
      --) shift; break ;;
      -o | +o | -O | +O) shift 2 || shift ;;
      --*) shift ;;
      [-+]*)
        [[ $1 == -*c* ]] && run_string=1
        [[ $1 == -*n* ]] && syntax_only=1
        [[ $1 == -*s* ]] && read_stdin=1
        shift
        ;;
      *) break ;;
    esac
  done
  ((syntax_only)) && return 0

  if ((run_string)); then
    (($#)) && check_source "$1" $((depth + 1)) "$origin" "$expanded"
  elif (($#)) && ((!read_stdin)); then
    check_install "$1"
  else
    case ${stdin-} in
      t*) check_source "${stdin:1}" $((depth + 1)) "$origin" "$expanded" ;;
      f*) check_install "${stdin:1}" ;;
      u) block "A shell reading commands from a pipe runs text the guard can't see. Run the commands directly instead." ;;
    esac
  fi
  return 0
}

# Find the shell snapshot the Bash tool sources and index its aliases and
# function names. Done once, and only when a command could be one of them.
load_snapshot() {
  ((snapshot_loaded)) && return 0
  snapshot_loaded=1

  local file
  for file in "${CLAUDE_CONFIG_DIR:-$HOME/.claude}"/shell-snapshots/snapshot-zsh-*.sh; do
    [[ -f $file && (-z $snapshot || $file -nt $snapshot) ]] && snapshot=$file
  done
  [[ -n $snapshot ]] || return 0

  # zsh writes each alias as one `alias -- name=value` line and each function
  # as a `name () {` line at column 0.
  snapshot_aliases=$'\n'$(awk '/^alias -- / { print substr($0, 10) }' "$snapshot")$'\n'
  snapshot_functions=" $(awk '/^[^ \t]+ \(\) \{$/ { printf "%s ", $1 }' "$snapshot")"
}

# An alias is text substitution: its value, then the rest of the words. The
# result is checked as a command of its own, with this alias marked expanded
# so `alias ls='ls -G'` doesn't loop.
#
# @param $@ the command's words
check_alias() {
  local name=$1 value
  shift
  [[ " $expanded " == *" $name "* ]] && return 0
  # Loaded here, not inside alias_value's subshell, so the index outlives it.
  load_snapshot
  value=$(alias_value "$name") || return 0
  check_source "$value $(quote_words "$@")" $((depth + 1)) snapshot "$expanded $name"
}

# @param $1 an alias name
# @return the alias's value with zsh's quoting removed, on stdout; non-zero if
#         the snapshot has no such alias
# Call load_snapshot first, in the parent shell; this runs in a subshell.
alias_value() {
  local rest=${snapshot_aliases#*$'\n'"$1"=}
  [[ $rest != "$snapshot_aliases" ]] || return 1
  unquote_alias "${rest%%$'\n'*}"
}

# zsh quotes an alias value as 'text' runs joined by \' (`'a '\''b'\'`), or
# leaves it bare when nothing in it needs quoting.
#
# @param $1 the value as the snapshot wrote it
# @return the value itself on stdout
unquote_alias() {
  local text=$1 plain=""
  while [[ -n $text ]]; do
    if [[ $text == "'"* ]]; then
      text=${text#"'"}
      plain+=${text%%"'"*}
      # An unclosed quote would leave text unchanged and loop forever.
      [[ $text == *"'"* ]] && text=${text#*"'"} || text=""
    elif [[ $text == \\* ]]; then
      plain+=${text:1:1}
      text=${text:2}
    else
      plain+=${text:0:1}
      text=${text:1}
    fi
  done
  echo "$plain"
}

# A function's body is walked with the call's words as its $1.. and "$@", so
# `acp "msg"` is checked as the git commands acp runs. One defined earlier in
# the command is found there, the last definition winning as it does in the
# shell; otherwise the snapshot's. A snapshot body shfmt can't parse is let
# through: it is the user's own code, not something Claude wrote.
#
# A function already being walked on this path is skipped, so `f() { f; f; };
# f` ends at once instead of doubling at every level.
#
# @param $@ the command's words
check_function() {
  local name=$1 tree
  local depth=$((depth + 1))
  shift
  [[ " $expanded " == *" fn:$name "* ]] && return 0
  local expanded="$expanded fn:$name"

  if [[ $inline_functions == *$'\n'"$name"$'\t'* ]]; then
    ((depth <= max_depth)) || block_too_deep
    tree=${inline_functions##*$'\n'"$name"$'\t'}
    walk_tree "${tree%%$'\n'*}" yes "$@"
    return 0
  fi

  load_snapshot
  [[ $snapshot_functions == *" $name "* ]] || return 0
  ((depth <= max_depth)) || return 0
  tree=$(parse_source "$(function_source "$name")") || return 0
  local origin=snapshot
  walk_tree "$tree" yes "$@"
}

# A function runs from its `name () {` line to the next function, or to the
# options and aliases that follow the last one. Counting braces would stop
# early: a heredoc or a nested function puts a `}` at column 0 inside a body.
#
# @param $1 a function name
# @return the function's definition on stdout
function_source() {
  awk -v header="$1 () {" '
    $0 == header { inside = 1; print; next }
    inside && (/^[^ \t]+ \(\) \{$/ || /^# Shell Options/ || /^alias -- /) { exit }
    inside { print }
  ' "$snapshot"
}

# @param $1 a word
# @return 0 if it is a short-flag cluster containing the letter in $2 (-n, -qn)
short_flag_has() {
  [[ $1 =~ ^-[a-zA-Z]*$2[a-zA-Z]*$ ]]
}

# Like short_flag_has, for options that take a value, which git lets ride in
# the same word (-bfoo, -qcfoo): the value is whatever follows the letter.
#
# @param $1 a word
# @param $2 the option letters, as a bracket expression's contents (bBt)
# @return 0 if the word is a short cluster reaching one of those letters
short_cluster_reaches() {
  [[ $1 =~ ^-[a-zA-Z]*[$2] ]]
}

# @param $@ the words of one command
check_command() {
  local name=${1##*/}
  local word

  case $name in
    git)
      check_git "$@"
      ;;

    nix)
      # Global options can come first (`nix -L profile install`), and the
      # word after profile that isn't an option is its subcommand.
      local profile=0
      for word in "${@:2}"; do
        [[ $word == -* ]] && continue
        if ((profile)); then
          [[ $word =~ ^(install|add)$ ]] &&
            block "Nix is for per-project environments only. Global tools come from homebrew/Brewfile; a project's go in its flake."
          break
        fi
        [[ $word == profile ]] && profile=1
      done
      ;;

    nix-env)
      for word in "${@:2}"; do
        if [[ $word == --install ]] || short_flag_has "$word" i; then
          block "Nix is for per-project environments only. Global tools come from homebrew/Brewfile; a project's go in its flake."
        fi
      done
      ;;

    abbr)
      check_abbr "${@:2}"
      ;;

    iris)
      for word in "${@:2}"; do
        [[ $word == -* ]] && continue
        [[ $word =~ ^(setup|uninstall)$ ]] &&
          block "iris $word rewrites the tracked shell RC. Make the change in ~/dotfiles by hand."
        break
      done
      ;;

    sed | gsed | perl)
      check_in_place "$@"
      ;;

    install.sh)
      check_install "$1"
      ;;
  esac
  return 0
}

# The git rules. Global options before the subcommand are skipped, keeping the
# -C path (for the checks that read the repo) and every -c value (for the
# signing check and inline aliases).
#
# @param $@ the words of one command, starting with git
check_git() {
  local git_dir=$cwd
  local word
  local -a configs=()
  shift

  while (($#)); do
    case $1 in
      -C)
        git_dir=$(resolve_path "${2-}") || git_dir=$cwd
        shift 2 || shift
        ;;
      -c) configs+=("${2-}"); shift 2 || shift ;;
      # The global options whose value is the next word, not the subcommand.
      --git-dir | --work-tree | --namespace | --config-env | --attr-source) shift 2 || shift ;;
      -*) shift ;;
      *) break ;;
    esac
  done
  (($#)) || return 0

  local sub=$1
  shift
  local -a args=("$@")
  local -a positionals=()
  for word in "${args[@]}"; do
    [[ $word == -* ]] || positionals+=("$word")
  done

  for word in "${args[@]}"; do
    [[ $word == --no-verify ]] &&
      block "--no-verify skips the repo's hooks. Fix what the hook reports instead."
    [[ $word == --no-gpg-sign ]] &&
      block "Commits stay signed. If signing fails, tell the user rather than turning it off."
  done
  for word in "${configs[@]}" "${args[@]}"; do
    # Git reads the key and a boolean case-insensitively, and an empty value
    # is false.
    [[ ${word,,} =~ ^(commit|tag)\.gpgsign=(false|no|off|0)?$ ]] &&
      block "Commits stay signed. If signing fails, tell the user rather than turning it off."
  done

  case $sub in
    commit)
      # The value after -m and friends is text, so `-m -n` is a message. In a
      # cluster, everything after a value-taking letter is its value (-mnote).
      local skip=0
      for word in "${args[@]}"; do
        if ((skip)); then
          skip=0
          continue
        fi
        case $word in
          --message | --file | --author | --date | --template | --reuse-message | \
            --reedit-message | --fixup | --squash | --trailer | --cleanup) skip=1 ;;
          --*) ;;
          -*)
            [[ ${word%%[mFCct]*} == *n* ]] &&
              block "git commit -n is --no-verify, which skips the repo's hooks. Fix what the hook reports instead."
            [[ $word =~ ^-[a-zA-Z]*[mFCct]$ ]] && skip=1
            ;;
        esac
      done
      ;;

    config)
      check_git_config "${args[@]}"
      ;;

    checkout)
      # --track and --orphan create a branch as surely as -b does. Paths
      # follow --, and a path may start with a dash.
      for word in "${args[@]}"; do
        [[ $word == -- ]] && break
        if [[ $word =~ ^(--track|--orphan)(=.*)?$ ]] || short_cluster_reaches "$word" bBt; then
          block "Never create a branch. Commit on the current branch, or say why it shouldn't land there and let the user decide."
        fi
      done
      # After `--` the words are paths, and a path checkout never guesses.
      for word in "${args[@]}"; do
        [[ $word =~ ^(--|--no-guess|--detach)$ ]] && return 0
      done
      check_git_guess checkout "$git_dir" "${positionals[@]}"
      ;;

    switch)
      for word in "${args[@]}"; do
        if [[ $word =~ ^(--create|--force-create|--track|--orphan)(=.*)?$ ]] || short_cluster_reaches "$word" cCt; then
          block "Never create a branch. Commit on the current branch, or say why it shouldn't land there and let the user decide."
        fi
      done
      for word in "${args[@]}"; do
        if [[ $word =~ ^(--no-guess|--detach)$ ]] || short_flag_has "$word" d; then
          return 0
        fi
      done
      check_git_guess switch "$git_dir" "${positionals[@]}"
      ;;

    branch)
      check_git_branch "${args[@]}"
      ;;

    worktree)
      check_git_worktree "${args[@]}"
      ;;

    fetch)
      # The first positional is the remote; the rest are refspecs.
      for word in "${positionals[@]:1}"; do
        integration_ref_name "$word" "$git_dir" >/dev/null && fetched_integration=1
      done
      ;;

    merge)
      check_git_merge "$git_dir" "${args[@]}"
      ;;

    pull)
      # Pulling develop while on develop is just updating it, and a rebase
      # pull is the catch-up the Git rules leave to the user's call. The first
      # positional names the remote, so a remote called staging is no merge.
      local current
      for word in "${args[@]}"; do
        [[ $word == --rebase* || $word == -r ]] && return 0
      done
      local name
      current=$(git -C "$git_dir" branch --show-current 2>/dev/null)
      for word in "${positionals[@]:1}"; do
        name=$(integration_ref_name "$word" "$git_dir") && [[ $name != "$current" ]] &&
          block "Pulling $word into ${current:-this branch} merges it. Never merge develop or staging into another branch; tell the user the branch is behind and let them decide."
      done
      ;;

    push)
      check_git_push "${args[@]}"
      ;;

    *)
      check_git_alias "$git_dir" "$sub" "${configs[@]}" -- "${args[@]}"
      ;;
  esac
  return 0
}

# Git expands an alias for any subcommand it doesn't know, so `git nb x` after
# `git config alias.nb 'checkout -b'` is `git checkout -b x`. A `!` alias runs
# its text in a shell with the arguments after it. Inline `-c alias.X=...`
# values win over the repo's config, as they do in git.
#
# @param $1 the repo directory
# @param $2 the subcommand as typed
# @param $@ the -c values, then --, then the subcommand's arguments
check_git_alias() {
  local dir=$1 sub=$2 value="" found=0 config
  shift 2

  while (($#)) && [[ $1 != -- ]]; do
    config=$1
    shift
    # Git lowercases the section and key, so `-c Alias.NB=...` counts.
    shopt -s nocasematch
    if [[ $config == "alias.$sub="* ]]; then
      value=${config#*=}
      found=1
    fi
    shopt -u nocasematch
  done
  shift

  [[ " $expanded " == *" git:$sub "* ]] && return 0
  if ((!found)); then
    value=$(git -C "$dir" config --get "alias.$sub" 2>/dev/null) || return 0
  fi

  if [[ $value == '!'* ]]; then
    value=${value:1}
  else
    value="git $value"
  fi
  check_source "$value $(quote_words "$@")" $((depth + 1)) command "$expanded git:$sub"
}

# `git checkout x` and `git switch x`, when x isn't a local branch but one
# remote has it, create a local x tracking that remote's copy. Only a single
# positional can be that guess; with two, the first is a commit and the rest
# are paths.
#
# @param $1 checkout or switch, for the message
# @param $2 the repo directory
# @param $@ the positionals after the subcommand
check_git_guess() {
  local sub=$1 dir=$2 remote
  shift 2
  (($# == 1)) || return 0
  [[ $1 == *"$marker"* || $1 == -* ]] && return 0

  git -C "$dir" show-ref --verify --quiet "refs/heads/$1" 2>/dev/null && return 0
  remote=$(git -C "$dir" for-each-ref --count=1 --format='%(refname:short)' "refs/remotes/*/$1" 2>/dev/null)
  [[ -n $remote ]] &&
    block "git $sub $1 has no local branch to switch to, so git would create one from $remote. Never create a branch; use \`git $sub --detach $remote\` to look at it, or ask the user."
  return 0
}

# The merge sources are the positionals; the value after -m, -F, -s or -X is
# not one. A source only known when it runs (`git merge "$(git rev-parse
# @{u})"`) could be develop, so it is blocked the way an unknown branch name
# is.
#
# @param $1 the repo directory
# @param $@ from $2 on, the arguments after `git merge`
check_git_merge() {
  local dir=$1 word skip=0
  shift

  for word in "$@"; do
    if ((skip)); then
      skip=0
      continue
    fi
    case $word in
      -m | -F | -s | -X | --message | --file | --strategy | --strategy-option | --into-name) skip=1 ;;
      -*) ;;
      *"$marker"*)
        block "The guard can't tell what $word merges, and it could be develop or staging. Merge a branch by name, or ask the user."
        ;;
      *)
        if integration_ref_name "$word" "$dir" >/dev/null ||
          { [[ $word == FETCH_HEAD ]] && fetch_head_is_integration "$dir"; }; then
          block "Never merge develop or staging into another branch; it pulls everyone's in-flight work into this history. Tell the user the branch is behind and let them decide."
        fi
        ;;
    esac
  done
  return 0
}

# develop and staging as a merge source: the bare name, a remote's copy
# (origin/develop), a full or partial ref (refs/heads/develop, heads/develop,
# remotes/origin/develop), a commit relative to one (develop~2, develop^,
# develop@{1}), or a refspec (+develop:local). feature/develop is a branch of
# its own unless `feature` really is a remote.
#
# @param $1 a ref as typed
# @param $2 the repo directory, for its remote names
# @return develop or staging on stdout; non-zero if it names neither
integration_ref_name() {
  local ref=${1#+} tracking=0
  ref=${ref%%:*}
  ref=${ref%%[~^@]*}
  ref=${ref#refs/}
  ref=${ref#heads/}
  [[ $ref == remotes/* ]] && tracking=1
  ref=${ref#remotes/}

  if [[ $ref =~ ^(develop|staging)$ ]]; then
    echo "$ref"
    return 0
  fi
  [[ $ref =~ ^([^/]+)/(develop|staging)$ ]] || return 1
  # Under remotes/ the first part is a remote by definition.
  if ((!tracking)); then
    git -C "$2" remote 2>/dev/null | grep -qxF "${BASH_REMATCH[1]}" || return 1
  fi
  echo "${BASH_REMATCH[2]}"
}

# FETCH_HEAD is whatever the last fetch marked for merge: the lines without
# not-for-merge. A fetch of develop earlier in this same command counts too,
# since the file on disk still holds the previous one.
#
# @param $1 the repo directory
# @return 0 if merging FETCH_HEAD merges develop or staging
fetch_head_is_integration() {
  ((fetched_integration)) && return 0

  local file
  file=$(git -C "$1" rev-parse --git-path FETCH_HEAD 2>/dev/null) || return 1
  [[ $file == /* ]] || file="$1/$file"
  grep -v $'\tnot-for-merge\t' "$file" 2>/dev/null | grep -qE "branch '(develop|staging)'"
}

# Reads stay allowed (`git config user.email`, `git config --global --get x`);
# what is blocked is a write to the global file or any other file in this
# repo, a hand-set identity, or signing turned off. Removing an identity key
# is no identity set by hand.
#
# @param $@ the arguments after `git config`
check_git_config() {
  local global=0 writes=0 removes=0 skip="" file="" target
  local word
  local -a positionals=()

  for word in "$@"; do
    if [[ -n $skip ]]; then
      [[ $skip == file ]] && file=$word
      skip=""
      continue
    fi
    case $word in
      --global) global=1 ;;
      --get* | -l | --list) return 0 ;;
      --unset | --unset-all | --remove-section) writes=1 removes=1 ;;
      --add | --replace-all | --edit | -e | --rename-section) writes=1 ;;
      --file | -f) skip="file" ;;
      --file=*) file=${word#*=} ;;
      # Options whose value is the next word, not a key or a value to set.
      --type | --default | --blob | --comment | --value) skip="value" ;;
      -*) ;;
      *) positionals+=("$word") ;;
    esac
  done

  # The subcommand form (git 2.46+): `git config set k v`, `git config get k`.
  case ${positionals[0]-} in
    unset | remove-section)
      writes=1 removes=1
      positionals=("${positionals[@]:1}")
      ;;
    set | edit | rename-section)
      writes=1
      positionals=("${positionals[@]:1}")
      ;;
    get | list | get-*)
      return 0
      ;;
  esac
  ((${#positionals[@]} >= 2)) && writes=1
  ((writes)) || return 0

  # Git lowercases the section and key, and reads a boolean case-insensitively.
  [[ ${positionals[0],,} =~ ^(commit|tag)\.gpgsign$ && ${positionals[1],,} =~ ^(false|no|off|0)?$ ]] &&
    ((!removes)) &&
    block "Commits stay signed. If signing fails, tell the user rather than turning it off."
  if [[ -n $file ]] && target=$(resolve_path "$file") && [[ $(realpath "$target" 2>/dev/null) == "$repo"/* ]]; then
    global=1
  fi
  ((global)) &&
    block "git config --global (or --file into ~/dotfiles) rewrites a tracked file and can replace its symlink. Edit it in ~/dotfiles instead."
  [[ ${positionals[0],,} =~ ^user\.(email|signingkey)$ ]] && ((!removes)) &&
    block "No per-repo user.email or user.signingkey set by hand; the identity follows the remote through ~/.gitconfig-work."
  return 0
}

# `git branch` lists, deletes and renames as well as creating. A name with
# none of the non-creating flags beside it is a new branch.
#
# @param $@ the arguments after `git branch`
check_git_branch() {
  local word
  local has_name=0

  for word in "$@"; do
    case $word in
      -d | -D | --delete | -m | -M | --move | -l | --list | -a | --all | \
        -r | --remotes | -v | -vv | --verbose | --show-current | -u | \
        --set-upstream-to* | --unset-upstream | --edit-description | \
        --contains* | --no-contains* | --merged* | --no-merged* | \
        --points-at* | --sort* | --format* | --column* | --no-column)
        return 0
        ;;
      -*) ;;
      *) has_name=1 ;;
    esac
  done

  ((has_name)) &&
    block "Never create a branch. Commit on the current branch, or say why it shouldn't land there and let the user decide."
  return 0
}

# `git worktree add PATH` with no ref invents a branch named after PATH;
# -b/-B name one outright. A ref or --detach checks out something that exists.
#
# @param $@ the arguments after `git worktree`
check_git_worktree() {
  [[ ${1-} == add ]] || return 0
  shift

  local word skip=0
  local -a positionals=()
  for word in "$@"; do
    if ((skip)); then
      skip=0
      continue
    fi
    case $word in
      --orphan*) block "Never create a branch, including through git worktree add --orphan. Ask the user." ;;
      --detach) return 0 ;;
      --reason) skip=1 ;;
      --*) ;;
      -*)
        short_cluster_reaches "$word" bB &&
          block "Never create a branch, including through git worktree add -b. Ask the user."
        short_flag_has "$word" d && return 0
        ;;
      *) positionals+=("$word") ;;
    esac
  done

  ((${#positionals[@]} == 1)) &&
    block "git worktree add with only a path creates a branch named after it. Pass an existing ref or --detach, or ask the user."
  return 0
}

# --force-with-lease alone passes after a plain fetch and drops a teammate's
# commit; --force-if-includes closes that. A bare --force, -f or +refspec
# overrides any lease given beside it.
#
# @param $@ the arguments after `git push`
check_git_push() {
  local word
  local bare_force=0 lease=0 includes=0

  for word in "$@"; do
    case $word in
      --force) bare_force=1 ;;
      --force-with-lease*) lease=1 ;;
      --force-if-includes) includes=1 ;;
      --*) ;;
      -*) short_flag_has "$word" f && bare_force=1 ;;
      +*) bare_force=1 ;;
    esac
  done

  ((bare_force || lease)) || return 0
  ((!bare_force && lease && includes)) && return 0
  block "A force push uses --force-with-lease --force-if-includes and nothing else, only after the user confirms it, and never on a shared branch or main."
}

# Mirrors zsh-abbr's own argument loop: the first action word wins wherever it
# sits, and with no action word any other argument means add (`abbr gs=x`,
# and `abbr -a gs x`, since -a isn't an option it knows). -g is --global, not
# git. --session and --dry-run leave zsh/abbreviations alone.
#
# @param $@ the arguments after `abbr`
check_abbr() {
  local word action="" has_args=0

  for word in "$@"; do
    case $word in
      --session | -S | --dry-run) return 0 ;;
      --) has_args=1; break ;;
      add | a | git | g | erase | e | rename | R | import-* | expand | x | \
        clear-session | c | export-aliases | list | list-abbreviations | l | \
        list-commands | L | -L | profile | version | --version | -v | help | \
        --help | load)
        [[ -n $action ]] && has_args=1
        action=${action:-$word}
        ;;
      --force | -f | --global | -g | --regular | -r | --user | -U | \
        --quiet | -q | --quieter | -qq) ;;
      *) has_args=1 ;;
    esac
  done

  [[ -z $action ]] && ((has_args)) && action=add
  [[ $action =~ ^(add|a|git|g|erase|e|rename|R|import-.*)$ ]] &&
    block "abbr rewrites zsh/abbreviations and drops its comments. Edit ~/dotfiles/zsh/abbreviations by hand."
  return 0
}

# An in-place edit writes a new file and renames it over the old path, so a
# symlinked dotfile becomes a copy that stops tracking the repo. GNU sed's
# --follow-symlinks is the one form that edits the target.
#
# @param $@ the words of one command, starting with sed, gsed or perl
check_in_place() {
  local tool=${1##*/}
  local word target
  local in_place=0
  shift

  for word in "$@"; do
    case $word in
      --follow-symlinks) return 0 ;;
      --in-place*) in_place=1 ;;
      # BSD sed's -I is in-place too; perl's is an include path, and perl's
      # -M/-m module names can hold an i.
      -I*) [[ $tool == perl ]] || in_place=1 ;;
      -M* | -m*) [[ $tool != perl && $word =~ ^-[0-9a-zA-Z]*i ]] && in_place=1 ;;
      # An i anywhere in a cluster: sed -Ei, perl -0pi, perl -pi.bak.
      -*) [[ $word =~ ^-[0-9a-zA-Z]*i ]] && in_place=1 ;;
    esac
  done
  ((in_place)) || return 0

  for word in "$@"; do
    [[ $word == -* ]] && continue
    target=$(resolve_path "$word") || continue
    [[ -L $target ]] &&
      block "$word is a symlink; $tool -i would replace it with a copy. Edit $(realpath "$target") instead."
  done
  return 0
}

# A path that can't be resolved (after `cd "$dir"`, or "$repo"/install.sh) is
# still blocked when it ends in install.sh: this repo's is by far the likeliest.
#
# @param $1 the script a shell, source or the command itself would run
check_install() {
  local target
  [[ -n $1 ]] || return 0
  if ! target=$(resolve_path "$1"); then
    [[ ${1##*/} == install.sh ]] &&
      block "The guard can't tell which install.sh $1 is, and this repo's must not run. Don't run install.sh to test a change; test the function in isolation with temporary destinations."
    return 0
  fi
  [[ -f $target && $(realpath "$target") == "$repo/install.sh" ]] &&
    block "Don't run install.sh to test a change; it installs packages and changes system files. Test the function in isolation with temporary destinations."
  return 0
}

check_source "$command" 0 command ""
exit 0
