# define: wordpress::addon
#
# This definition manages a WordPress addon (plugin or theme). It can be
# instantiated independently, but the recommended way of benefiting from this
# resource is through the `$wp_plugins` / `$wp_themes` parameters of the
# defined type `wordpress::instance`, because it automates some parameters,
# like `owner`, `group` and `path`, taking the right ones from the WordPress
# instance.
#
# Parameters:
#   [*slug*]
#     Addon slug (the directory name where addon is installed).
#   [*path*]
#     Absolute path to the WordPress installation directory.
#   [*owner*]
#     [String] Defines owner of the addon files. Defaults to 'root'.
#   [*group*]
#     [String] Defines group of the addon files. Defaults to '0'.
#   [*install*]
#     [Boolean] Whether to install (true) or uninstall (false) the addon.
#   [*activate*]
#     [Boolean] Whether to activate (true) or deactivate (false) the addon.
#   [*delete*]
#     [Boolean] Whether to delete (true) or not (false) the addon files when
#     uninstalling.
#   [*install_composer_packages*]
#     [Boolean] Whether to install (true) or not (false) the composer packages
#     required by the addon through the file `composer.json` when it is
#     available. Only used with provider `git`. Composer must be installed
#     (not accomplished by this module) and globally available prior to using
#     this feature. Defaults to `true`.
#   [*install_nodejs_packages*]
#     [Boolean] Whether to install (true) or not (false) the Node.js packages
#     required by the addon through the file `package.json` when it is
#     available. Only used with provider `git`. npm must be installed
#     (not accomplished by this module) and globally available prior to using
#     this feature. Defaults to `true`.
#   [*install_bower_packages*]
#     [Boolean] Whether to install (true) or not (false) the bower packages
#     required by the addon through the file `package.json` when it is
#     available. Only used with provider `git`. Bower must be installed
#     prior to using this feature. If not globally available, you should
#     include it in the addon `package.json` to have it installed at least
#     locally before executing this feature. Defaults to `true`.
#
# Actions:
#
# Requires:
#
# Sample Usage:
#  wordpress::addon { 'akismet':
#    path     => '/opt/wordpress',
#    owner    => 'vagrant',
#    group    => 'vagrant',
#    install  => true,
#    activate => true,
#    version  => '3.1.2',
#    type     => 'plugin',
#  }
define wordpress::addon (
  $slug,
  $path,
  $owner                 = 'root',
  $group                 = '0',
  $install               = undef,
  $activate              = undef,
  $delete                = undef,
  $version               = undef,
  $type                  = 'plugin',
  $provider              = 'wpcli',
  $source                = undef,
  $manage_composer_deps  = true,
  $manage_nodejs_deps    = true,
  $manage_bower_deps     = true,
) {

  $common = {
    $title => {
      'slug'                  => $slug,
      'path'                  => $path,
      'owner'                 => $owner,
      'group'                 => $group,
      'install'               => $install,
      'activate'              => $activate,
      'delete'                => $delete,
      'version'               => $version,
      'type'                  => $type,
      'source'                => $source,
      'manage_composer_deps'  => $manage_composer_deps,
      'manage_nodejs_deps'    => $manage_nodejs_deps,
      'manage_bower_deps'     => $manage_bower_deps,
    }
  }
  $res = $provider ? {
    /(wpackagist|wpcli)/ => wordpress::addon::wpcli,
    'git'                => wordpress::addon::git,
    default              => undef
  }
  if $res == undef {
    fail("Unsupported provider ${provider}")
  } else {
    create_resources($res, $common)
  }

}
