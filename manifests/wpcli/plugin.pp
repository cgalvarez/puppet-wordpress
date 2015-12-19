# define: wordpress::wpcli::plugin
#
# This definition manages a WordPress plugin. It can be instantiated
# independently, but the recommended way of benefiting from this resource is
# through the `$plugins` parameter of `wordpress::instance` defined type,
# because it automates some parameters, like `owner`, `group` and `path`, using
# automatically the right ones from the WordPress instance.
#
# Parameters:
#   [*slug*]     - Plugin slug (the directory name when plugin is installed).
#   [*path*]     - Absolute path to the WordPress installation directory.
#   [*owner*]    - [String] Defines owner of the plugin files. Defaults to
#                  'root'.
#   [*group*]    - [String] Defines group of the plugin files. Defaults to '0'.
#   [*install*]  - [Boolean] Whether to install (true) or uninstall (false) the
#                  plugin.
#   [*activate*] - [Boolean] Whether to activate (true) or deactivate (false)
#                  the plugin.
#   [*delete*]   - [Boolean] Whether to delete (true) or not (false) the plugin
#                  files when uninstalling.
#
# Actions:
#
# Requires:
#
# Sample Usage:
#  wordpress::wpcli::plugin { 'akismet':
#    path     => '/opt/wordpress',
#    owner    => 'vagrant',
#    group    => 'vagrant',
#    install  => true,
#    activate => true,
#    version  => '3.1.2',
#  }
define wordpress::wpcli::plugin (
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
      fail("'activate' and 'uninstall' cannot be used in conjunction (plugin '${slug}' @ '${path}')")
    }
    if $delete == true {
      fail("'activate' and 'delete' cannot be used in conjunction (plugin '${slug}' @ '${path}')")
    }
  }
  if $install == true and $delete == true {
    fail("'install' and 'delete' cannot be used in conjunction (plugin '${slug}' @ '${path}')")
  }

  if $install != undef {
    # TODO: Provide support for specific (--activate-network) and global flags
    # Check:  http://wp-cli.org/commands/plugin/install/
    #         http://wp-cli.org/commands/plugin/uninstall/
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
    # Check:  http://wp-cli.org/commands/plugin/activate/
    #         http://wp-cli.org/commands/plugin/deactivate/
    $action = $activate ? {
      true      => "activate ${slug} --path=${path}",
      false     => "deactivate ${slug}",
      default   => undef,
    }
  }

  if $action != undef {
    $install_dir = "${path}/wp-content/plugins/${slug}"
    $exec_title  = "Execute WP-CLI for ${path}/wp-content/plugin/${slug}"
    if $install == true {
      exec { $exec_title:
        command => "wp plugin ${action} --path=${path}",
        unless  => "wp plugin is-installed ${slug} --path=${path}",
        user    => $owner,
        group   => $group,
        before  => Exec["Set ownership for ${path}"],
        notify  => Exec["Set ownership for ${path}"],
      }
    } else {
      exec { $exec_title:
        command => "wp plugin ${action} --path=${path}",
        onlyif  => "wp plugin is-installed ${slug} --path=${path}",
        user    => $owner,
        group   => $group,
        before  => Exec["Set ownership for ${path}"],
        notify  => Exec["Set ownership for ${path}"],
      }
    }
  }

}
