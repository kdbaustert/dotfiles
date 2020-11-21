#! /usr/bin/env sh

info "Installing composer global packages."
composer=(
  laravel/installer
  laravel/valet
  phpunit/phpunit
  squizlabs/php_codesniffer
  escapestudios/symfony2-coding-standard
  dealerdirect/phpcodesniffer-composer-installer
  wp-coding-standards/wpcs
  phpcompatibility/phpcompatibility-wp
  friendsofphp/php-cs-fixer
)

info ${composer[@]}
composer global require ${composer[@]}
