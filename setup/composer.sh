#! /usr/bin/env sh


info "Installing composer global packages."
composer global require laravel/installer
composer global require laravel/valet
composer global require phpunit/phpunit
composer global require squizlabs/php_codesniffer
composer global require escapestudios/symfony2-coding-standard
composer global require dealerdirect/phpcodesniffer-composer-installer
composer global require wp-coding-standards/wpcs
composer global require phpcompatibility/phpcompatibility-wp
composer global require friendsofphp/php-cs-fixer