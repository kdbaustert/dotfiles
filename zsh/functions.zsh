#!/usr/bin/env zsh

# Extract most know archives with one command
extract() {
  if [ -f $1 ]; then
    case $1 in
    *.tar.bz2) tar xjf $1 ;;
    *.tar.gz) tar xzf $1 ;;
    *.bz2) bunzip2 $1 ;;
    *.rar) unrar e $1 ;;
    *.gz) gunzip $1 ;;
    *.tar) tar xf $1 ;;
    *.tbz2) tar xjf $1 ;;
    *.tgz) tar xzf $1 ;;
    *.zip) unzip $1 ;;
    *.Z) uncompress $1 ;;
    *.7z) 7z x $1 ;;
    *) echo "'$1' cannot be extracted via extract()" ;;
    esac
  else
    echo "'$1' is not a valid file"
  fi
}

# GIT ADD, COMMIT & PUSH
function acp() {
  git add .
  git commit -m "$1"
  git push
}

function compress() {
  tar cvzf $1.tar.gz $1
}

# MAKE FOLDER AND CD INTO IT
mcd() {
  mkdir -p "$@" && cd "$@"
}

# CHECK SHELL
shell() {
  ps | grep $(echo $$) | awk '{ print $4 }'
}

function compress() {
  tar cvzf $1.tar.gz $1
}

# Create a data URL from a file
function dataurl() {
  local mimeType=$(file -b --mime-type "$1")
  if [[ $mimeType == text/* ]]; then
    mimeType="${mimeType};charset=utf-8"
  fi
  echo "data:${mimeType};base64,$(openssl base64 -in "$1" | tr -d '\n')"
}

#Create a new WordPress project install
install_wp() {

  if [ "$1" != "" ]; then
    PROJECT_NAME=$1

    # Main projects directory
    cd ~/Development

    #Create directory & cd into it
    mkdir $PROJECT_NAME
    cd $PROJECT_NAME

    # Create gitignore
    wp_gitignore

    echo "Setting up WordPress core.."

    wp core download
    wp core config \
      --dbname=$PROJECT_NAME \
      --dbuser="root" \
      --dbpass="root" \
      --dbprefix="wp_"

    wp db create

    echo "Running valet secure.."

    valet secure

    wp core install \
      --url="https://${PROJECT_NAME}.test" \
      --title="$PROJECT_NAME" \
      --admin_user="kenny" \
      --admin_password="password" \
      --admin_email="kenny@growwithom.com"

    # delete default installed plugins and themes we don't need
    echo "Cleaning up WordPress junk"

    wp plugin delete hello akismet
    wp theme delete twentynineteen twentyseventeen

    echo "New WordPress install complete"

    echo "https://${PROJECT_NAME}.test"

  else
    echo "Please enter a project name"
  fi
}

# reload the zsh session. From OMZ:plugins/zsh_reload
zreload() {
  local cache="$ZSH_CACHE_DIR"
  autoload -U compinit zrecompile
  compinit -i -d "$cache/zcomp-$HOST"

  for f in ${ZDOTDIR:-~}/.zshrc "$cache/zcomp-$HOST"; do
    zrecompile -p $f && command rm -f $f.zwc.old
  done

  # Use $SHELL if available; remove leading dash if login shell
  [[ -n "$SHELL" ]] && exec ${SHELL#-} || exec zsh
}

fd() {
  local dir
  dir=$(find ${1:-.} -path '*/\.*' -prune \
    -o -type d -print 2>/dev/null | fzf +m) &&
    cd "$dir"
}
