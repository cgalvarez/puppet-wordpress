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
define wordpress::addon::wpcli (
  $slug,
  $path,
  $owner                = 'root',
  $group                = '0',
  $install              = undef,
  $activate             = undef,
  $delete               = undef,
  $version              = undef,
  $type                 = 'plugin',
  $provider             = 'wpcli',
  $source               = undef,
  $manage_composer_deps = true,
  $manage_nodejs_deps   = true,
  $manage_bower_deps    = true,
) {

  include wordpress::wpcli

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
  validate_string($version, $owner, $group)
  validate_re($type, '^(theme|plugin)$',
    "${type} is not supported for type. Allowed values are 'theme' and 'plugin'.")

  # Resource defaults
  Exec {
    path      => ['/bin', '/sbin', '/usr/bin', '/usr/sbin', '/usr/local/bin'],
    logoutput => 'on_failure',
  }

  if $activate == true {
    if $install == false {
      fail("'activate' and 'uninstall' cannot be used in conjunction (${type} '${slug}' for '${path}')")
    }
    if $delete == true {
      fail("'activate' and 'delete' cannot be used in conjunction (${type} '${slug}' for '${path}')")
    }
  }
  if $install == true and $delete == true {
    fail("'install' and 'delete' cannot be used in conjunction (${type} '${slug}' for '${path}')")
  }

  if $install != undef {
    # TODO: Provide support for specific (--activate-network) and global flags
    # Check:  http://wp-cli.org/commands/$type/install/
    #         http://wp-cli.org/commands/$type/uninstall/
    $actions = $install ? {
      true         => $activate ? {
        true       => $version ? {
          undef    => ["install ${slug} --force --activate"],
          default  => ["install ${slug} --force --activate --version=${version}"],
        },
        default    => $version ? {
          undef    => ["install ${slug} --force"],
          default  => ["install ${slug} --force --version=${version}"],
        },
      },
      false        => $delete ? {
        true       => $type ? {
          'plugin' => ["uninstall ${slug} --deactivate"],
          'theme'  => $delete ? {
            true   => ["delete ${slug}"],
            default => [],
          },
          default  => [],
        },
        default    => $type ? {
          'plugin' => ["uninstall ${slug} --deactivate --skip-delete"],
          default  => [],
        },
      },
      default      => [],
    }
    $check = "wp ${type} is-installed ${slug} --path=${path}"
  } elsif $activate != undef {
    # TODO: Provide support for specific (--all|--network) and global flags
    # Check:  http://wp-cli.org/commands/$type/activate/
    #         http://wp-cli.org/commands/$type/deactivate/
    $actions = $activate ? {
      true       => ["activate ${slug}"],
      false      => $type ? {
        'plugin' => ["deactivate ${slug}"],
        default  => [],
      },
      default    => [],
    }
    $status = $activate ? {
      true    => 'Inactive',
      false   => 'Active',
      default => '',
    }
    $check = "wp ${type} status ${slug} --path=${path} | grep 'Status: ${status}'"
  }

  if !empty($actions) {
    $install_dir = "${path}/wp-content/${type}s/${slug}"
    $exec_title  = "Execute WP-CLI for ${path}/wp-content/${type}s/${slug}"
    if $install == true {
      $actions.each |String $action| {
        exec { "wp ${type} ${action} --path=${path}":
          unless  => $check,
          user    => $owner,
          group   => $group,
          notify  => Exec["Set ownership for ${path}"],
        }
      }
    } else {
      $actions.each |String $action| {
        exec { "wp ${type} ${action} --path=${path}":
          onlyif  => $check,
          user    => $owner,
          group   => $group,
          notify  => Exec["Set ownership for ${path}"],
        }
      }
    }
  }

}
