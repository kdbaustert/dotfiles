export COLORTERM="truecolor"

export SPROMPT="zsh: correct %F{red}'%R'%f to %F{blue}'%r'%f [%B%Uy%u%bes, %B%Un%u%bo, %B%Ue%u%bdit, %B%Ua%u%bbort]?"

export EDITOR='nvim'
export VISUAL=$EDITOR
export DOTFILES=$HOME/dotfiles
export LANG='en_US.UTF-8'
export WORDCHARS='~!#$%^&*(){}[]<>?.+;' # sane moving between words on the prompt
export PATH="/usr/local/sbin:$PATH"
export PROMPT_EOL_MARK='' # hide % at end of output
export LS_COLORS="$(vivid generate molokai)"

if [ -d "$HOME/.nvm" ]; then
  export NVM_DIR="$HOME/.nvm"
fi

if [ -d "$HOME/.composer/vendor/bin" ]; then
  export PATH="$HOME/.composer/vendor/bin:$PATH"
fi

if [ -d "$HOME/.gem" ]; then
  export GEM_HOME="$HOME/.gem"
fi
