#! /usr/bin/env sh

info "Installing npm global packages."
npm=(
  @vue/cli
  caniuse-cmd
  eslint
  prettier
  eslint-plugin-prettier
  eslint-config-prettier
  eslint-plugin-vue
  eslint-config-standard
  babel-eslint
  generator-code
  yo
  speed-test
  fast-cli
  fkill-cli
  vtop
  vsce
  @vue/cli-service-global
  cli-error-notifier
  electron
  http-server
  npm-check
  stylelint
  stylelint-config-standard
)

info ${npm[@]}
npm install -g ${npm[@]}
