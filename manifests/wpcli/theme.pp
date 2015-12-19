# define: wordpress::wpcli::theme
#
# This definition manages a WordPress theme. It can be instantiated
# independently, but the recommended way of benefiting from this resource is
# through the `$themes` parameter of `wordpress::instance` defined type,
# because it automates some parameters, like `owner`, `group` and `path`, using
# automatically the right ones from the WordPress instance.
#
# Parameters:
#   [*slug*]     - Theme slug (the directory name when theme is installed).
#   [*path*]     - Absolute path to the WordPress installation directory.
#   [*owner*]    - [String] Defines owner of the theme files. Defaults to
#                  'root'.
#   [*group*]    - [String] Defines group of the theme files. Defaults to '0'.
#   [*install*]  - [Boolean] Whether to install (true) or uninstall (false) the
#                  theme.
#   [*activate*] - [Boolean] Whether to activate (true) or deactivate (false)
#                  the theme.
#   [*delete*]   - [Boolean] Whether to delete (true) or not (false) the theme
#                  files when uninstalling.
#
# Actions:
#
# Requires:
#
# Sample Usage:
#  wordpress::wpcli::theme { 'zerif-lite':
#    path     => '/opt/wordpress',
#    owner    => 'vagrant',
#    group    => 'vagrant',
#    install  => true,
#    activate => false,
#    version  => '1.8.3.0',
#  }
define wordpress::wpcli::theme (
  $slug,
  $path,
  $owner    = 'root',
  $group    = '0',
  $install  = undef,
  $activate = undef,
  $delete   = undef,
  $version  = undef,
) {

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

  # Resource defaults
  Exec {
    path      => ['/bin', '/sbin', '/usr/bin', '/usr/sbin', '/usr/local/bin'],
    logoutput => 'on_failure',
  }

  if $activate == true {
    if $install == false {
      fail("'activate' and 'uninstall' cannot be used in conjunction (theme '${slug}' @ '${path}')")
    }
    if $delete == true {
      fail("'activate' and 'delete' cannot be used in conjunction (theme '${slug}' @ '${path}')")
    }
  }
  if $install == true and $delete == true {
    fail("'install' and 'delete' cannot be used in conjunction (theme '${slug}' @ '${path}')")
  }

  if $install != undef {
    # TODO: Provide support for specific (--activate-network) and global flags
    # Check:  http://wp-cli.org/commands/theme/install/
    #         http://wp-cli.org/commands/theme/uninstall/
    $action = $install ? {
      true        => $activate ? {
        true      => $version ? {
          undef   => "install ${slug} --force --activate",
          default => "install ${slug} --force --activate --version=${version}",
        },
        default   => $version ? {
          undef   => "install ${slug} --force",
          default => "install ${slug} --force --version=${version}",
        },
      },
      false       => $delete ? {
        true      => "uninstall ${slug} --deactivate",
        default   => "uninstall ${slug} --deactivate --skip-delete",
      },
      default     => undef
    }
  } elsif $activate != undef {
    # TODO: Provide support for specific (--all|--network) and global flags
    # Check:  http://wp-cli.org/commands/theme/activate/
    #         http://wp-cli.org/commands/theme/deactivate/
    $action = $activate ? {
      true      => "activate ${slug} --path=${path}",
      false     => "deactivate ${slug}",
      default   => undef,
    }
  }

  if $action != undef {
    $install_dir = "${path}/wp-content/themes/${slug}"
    $exec_title  = "Execute WP-CLI for ${path}/wp-content/theme/${slug}"
    if $install == true {
      exec { $exec_title:
        command => "wp theme ${action} --path=${path}",
        unless  => "wp theme is-installed ${slug} --path=${path}",
        user    => $owner,
        group   => $group,
        before  => Exec["Set ownership for ${path}"],
      }
    } else {
      exec { $exec_title:
        command => "wp theme ${action} --path=${path}",
        onlyif  => "wp theme is-installed ${slug} --path=${path}",
        user    => $owner,
        group   => $group,
        before  => Exec["Set ownership for ${path}"],
      }
    }
  }

}
