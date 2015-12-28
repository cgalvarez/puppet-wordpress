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
define wordpress::addon::git (
  $slug,
  $path,
  $source,
  $type,
  $version               = undef,
  $owner                 = 'root',
  $group                 = '0',
  $install               = undef,
  $activate              = undef,
  $delete                = undef,
  $manage_composer_deps  = true,#
  $manage_nodejs_deps    = true,#
  $manage_bower_deps     = true,#
) {

  if !defined(Package['git']) {
    include git
  }

  # Perform validations
  if $activate != undef {
    validate_bool($activate)
  }
  if $delete != undef {
    validate_bool($delete)
  }
  if $install != undef {
    validate_bool($install)
  }
  if $path != undef {
    validate_absolute_path($path)
  }
  validate_string($version, $owner, $group, $type, $source)
  validate_re($type, '^(theme|plugin)$',
    "${type} is not supported for type. Allowed values are 'theme' and 'plugin'.")
  validate_re($source, '\Agit@[A-Za-z\.\-_]+:[A-Za-z\.\-_\/]+.git\z',
    "Git source must be a valid git source with the syntax 'git@host:path/to/project.git' ==> provided: ${source}")
  if $source == undef or $source == '' {
    fail("Source is required when using provider 'git' (${type} ${slug} for ${path}).")
  }

  # Resource defaults
  Exec {
    path      => ['/bin', '/sbin', '/usr/bin', '/usr/sbin', '/usr/local/bin'],
    logoutput => 'on_failure',
    cwd       => "${path}/wp-content/${type}s/${slug}",
    user      => $owner,
    timeout   => 0,
  }

  # Add host to known_hosts of both, owner and roott
  $host = $source.match(/git@([^:]+)/)
  $root = 'root'
  if !defined(Exec["${host[1]} to ${root} known_hosts"]) {
    exec { "${host[1]} to ${root} known_hosts":
      command => "ssh -T ${host[0]} -o StrictHostKeyChecking=no; echo success",
      user    => $root,
      group   => $root,
      unless  => "ssh-keygen -H -F ${host[1]}",
    }
    exec { "${host[1]} to ${owner} known_hosts":
      command => "ssh -T ${host[0]} -o StrictHostKeyChecking=no; echo success",
      user    => $owner,
      group   => $group,
      unless  => "ssh-keygen -H -F ${host[1]}",
    }
  }

  if $install != undef {
    vcsrepo { "${path}/wp-content/${type}s/${slug}":
      ensure    => $install ? {
        false   => absent,
        default => present,
      },
      provider  => git,
      source    => $source,
      revision  => pick_default($version, 'master'),
      owner     => $owner,
      group     => $group,
      require   => [
        Package['git'],
        Exec["${host[1]} to ${root} known_hosts"],
        Exec["${host[1]} to ${owner} known_hosts"],
      ],
    }
  }

  # Manage de/activation with wpcli before/after vcsrepo based on $install
  if $install != undef {
    $common_params = {
      'slug'  => $slug,
      'path'  => $path,
      'owner' => $owner,
      'group' => $group,
      'type'  => $type,
    }
    $addon = {
      "${path}/wp-content/${type}s/${slug}" => $install ? {
        true       => {
          activate  => $activate,
          require  => Vcsrepo["${path}/wp-content/${type}s/${slug}"],
        },
        false      => {
          activate  => $activate,
          before   => Vcsrepo["${path}/wp-content/${type}s/${slug}"],
        },
        default    => {},
      }
    }
    create_resources(wordpress::addon::wpcli, $addon, $common_params)
  }

  if $manage_composer_deps {
    exec { "${path}: ${type} ${slug} composer deps":
      command     => 'composer install',
      environment => "COMPOSER_HOME=/home/${owner}/.composer",
      creates     => "${path}/wp-content/${type}s/${slug}/composer.lock",
      onlyif      => "test -f ${path}/wp-content/${type}s/${slug}/composer.json",
      require     => Vcsrepo["${path}/wp-content/${type}s/${slug}"],
      before      => Exec["Set ownership for ${path}"],
      notify      => Exec["Set ownership for ${path}"],
    }
  }

  #if $manage_nodejs_deps {
  #}

  #if $manage_bower_deps {
  #}

}
