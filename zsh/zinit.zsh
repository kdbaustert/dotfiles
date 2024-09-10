# #==============================================================#
# ## Setup zinit                                                ##
# #==============================================================#

if [[ ! -f $HOME/.zi/bin/zi.zsh ]]; then
  print -P "%F{33}▓▒░ %F{160}Installing (%F{33}z-shell/zi%F{160})…%f"
  command mkdir -p "$HOME/.zi" && command chmod g-rwX "$HOME/.zi"
  command git clone -q --depth=1 --branch "main" https://github.com/z-shell/zi "$HOME/.zi/bin" && \
    print -P "%F{33}▓▒░ %F{34}Installation successful.%f%b" || \
    print -P "%F{160}▓▒░ The clone has failed.%f%b"
fi

source "$HOME/.zi/bin/zi.zsh"
autoload -Uz _zi
(( ${+_comps} )) && _comps[zi]=_zi

declare -A _bpicks=()
if [[ $OSTYPE == darwin* ]] && [[ $CPUTYPE == arm* ]]; then
  _bpicks[rust]='*(x86_64|arm)*darwin*'
  _bpicks[haskell]='*darwin*(x86_64|arm)*'
  _bpicks[jq]='*osx*(amd64|arm)*'
  _bpicks[gh]='*macos*(amd64|arm)*'
  _bpicks[exa]='*macos*(x86_64|arm)*'
  _bpicks[starship]="*aarch64-apple*.tar.gz"
fi

zi light-mode for z-shell/z-a-meta-plugins @annexes @ext-git z-shell/H-S-MW

zi lucid light-mode for \
  as"command" from"gh-r" atload'eval "$(starship init zsh)"' bpick="*aarch64-apple*.tar.gz" \
  starship/starship

setopt promptsubst

zi ice lucid wait="0" pick="asdf.sh"
zi light $HOME/.asdf

# zi snippet OMZ::lib/key-bindings.zsh

zi from"gh-r" as"null" for \
  sbin"**/fd" @sharkdp/fd \
  sbin"**/bat" @sharkdp/bat \
  sbin"**/bat" @sharkdp/bat \
  sbin"**/exa -> exa" atclone"cp -vf completions/exa.zsh _exa" ogham/exa

zi light-mode for pick'misc/quitcd/quitcd.zsh' as'program' nocompile \
  sbin make \
    jarun/nnn`  `

zi ice lucid wait has'fzf'
zi light Aloxaf/fzf-tab

zi ice wait'0b' lucid
zi light b4b4r07/enhancd

# zi ice lucid wait as'completion' blockf has'fd'
# zi snippet https://github.com/ohmyzsh/ohmyzsh/blob/master/plugins/fd/_fd

zi ice lucid wait as'completion'
zi light zsh-users/zsh-completions

zi ice wait lucid as'program' from'gh-r' sbin'**/delta -> delta'
zi light dandavison/delta

zi ice lucid wait as'program' from"gh-r" has'fzf'
zi light denisidoro/navi

zi light zpm-zsh/dircolors-material

zi ice as"command" from"gh-r" mv"zoxide* -> zoxide" \
  eval"./zoxide init zsh"
zi light ajeetdsouza/zoxide

zi ice eval"dircolors -b LS_COLORS" \
  atload'zstyle ":completion:*" list-colors “${(s.:.)LS_COLORS}”'
zi light trapd00r/LS_COLORS

zi light-mode for id-as'pnpm' from'gh-r' bpick'*-linux-x64' as'program' \
  atinit'export PNPM_HOME=$ZPFX/bin; [[ -z $NODE_PATH ]] && \
  export NODE_PATH=$PWD' sbin'pnpm* -> pnpm' nocompile \
    pnpm/pnpm

zi lucid as'command' pick'bin/pyenv' atinit'export PYENV_ROOT="$PWD"' \
    atclone'PYENV_ROOT="$PWD" ./libexec/pyenv init - > zpyenv.zsh' \
    atpull"%atclone" src"zpyenv.zsh" nocompile'!' for \
        pyenv/pyenv

zi wait lucid for \
 atinit"ZI[COMPINIT_OPTS]=-C; zpcompinit; zicompinit; zicdreplay" \
  z-shell/fast-syntax-highlighting \
 blockf \
    zsh-users/zsh-completions \
 atload"!_zsh_autosuggest_start" \
  zsh-users/zsh-autosuggestions

zi ice lucid wait as'completion' blockf pick'src/go' src'src/zsh'
zi light zchee/zsh-completions

ZSH_AUTOSUGGEST_USE_ASYNC=true

# zi ice wait lucid
# zi snippet "OMZ::lib/completion.zsh"

zi wait lucid for \
  has'exa' atinit'AUTOCD=1' \
  zplugin/zsh-exa

zi ice wait lucid pick"h.sh"
zi light paoloantinori/hhighlighter
zi light zpm-zsh/ssh

zi load ellie/atuin

zi ice wait lucid reset \
 atclone"[[ -z \${commands[dircolors]} ]] && local P=g
    \${P}sed -i '/DIR/c\DIR 38;5;63;1' LS_COLORS
    \${P}dircolors -b LS_COLORS >! clrs.zsh" \
 atpull'%atclone' pick"clrs.zsh" nocompile'!' \
 atload'zstyle ":completion:*:default" list-colors "${(s.:.)LS_COLORS}";'
zi light trapd00r/LS_COLORS

zi light-mode for from'gh-r' as'program' \
  atinit'export PATH="$HOME/.yarn/bin:$PATH"' mv'yarn* -> yarn' \
  pick"yarn/bin/yarn" bpick'*.tar.gz' \
    yarnpkg/yarn

zi ice wait"0" lucid
zi light htlsne/zinit-rbenv

export NVM_LAZY_LOAD=true
zi light lukechilds/zsh-nvm

zi ice lucid wait"0a" from"gh-r" as"program" atload'eval "$(mcfly init zsh)"'
zi light cantino/mcfly

myfzf () {
        local bindir="/home/sg/.zi/plugins/junegunn---fzf"
        local -x GEM_HOME="/home/sg/.zi/plugins/junegunn---fzf"
        "$bindir"/"fzf" "$@"
}
