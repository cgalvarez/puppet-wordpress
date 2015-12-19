## 2015-12-19 - Release v1.0.2

- Fixes checking for installed plugins/themes with WP-CLI.
- Keeps downloaded WP tar package for improving provisioning.
- Harder security permissions for `wp-config.php`.
- Now ownership/permissions of installation dir is the very last thing to be executed, and only when required.
- Some code refactoring and optimizations.

## 2015-12-13 - Release v1.0.1

- Fixes plugins/themes order execution and ownership.

## 2015-12-10 - Release v1.0.0

- Defaults to install latest available version of WP if no version provided.
- Multiple WP instances can be provided through Hiera.
- Adds WP-CLI support.
- Adds ability of installing WP plugins/themes with WP-CLI through new defines `wordpress::wpcli::plugin` and `wordpress::wpcli::theme`.

## 2015-10-22 - Fork from hunner/puppet-wordpress 1.0.0

- Initial fork from hunner/puppet-wordpress 1.0.0