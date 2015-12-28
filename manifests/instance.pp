# == Definition: wordpress::instance
#
# This module manages wordpress
#
# === Parameters
#
# [*install_dir*]
#   Specifies the directory into which wordpress should be installed. Default:
#   /opt/wordpress
#
# [*install_url*]
#   Specifies the url from which the wordpress tarball should be downloaded.
#   Default: http://wordpress.org
#
# [*version*]
#   Specifies the version of wordpress to install. Default: 3.8
#
# [*create_db*]
#   Specifies whether to create the db or not. Default: true
#
# [*create_db_user*]
#   Specifies whether to create the db user or not. Default: true
#
# [*db_name*]
#   Specifies the database name which the wordpress module should be configured
#   to use. Required.
#
# [*db_host*]
#   Specifies the database host to connect to. Default: localhost
#
# [*db_user*]
#   Specifies the database user. Required.
#
# [*db_password*]
#   Specifies the database user's password in plaintext. Default: password
#
# [*wp_owner*]
#   Specifies the owner of the wordpress files. Default: root
#
# [*wp_group*]
#   Specifies the group of the wordpress files. Default: 0 (*BSD/Darwin
#   compatible GID)
#
# [*wp_lang*]
#   WordPress Localized Language. Default: ''
#
#
# [*wp_plugin_dir*]
#   WordPress Plugin Directory. Full path, no trailing slash. Default: WordPress Default
#
# [*wp_additional_config*]
#   Specifies a template to include near the end of the wp-config.php file to add additional options. Default: ''
#
# [*wp_table_prefix*]
#   Specifies the database table prefix. Default: wp_
#
# [*wp_proxy_host*]
#   Specifies a Hostname or IP of a proxy server for Wordpress to use to install updates, plugins, etc. Default: ''
#
# [*wp_proxy_port*]
#   Specifies the port to use with the proxy host.  Default: ''
#
# [*wp_multisite*]
#   Specifies whether to enable the multisite feature. Requires `wp_site_domain` to also be passed. Default: `false`
#
# [*wp_site_domain*]
#   Specifies the `DOMAIN_CURRENT_SITE` value that will be used when configuring multisite. Typically this is the address of the main wordpress instance.  Default: ''
#
# === Requires
#
# === Examples
#
define wordpress::instance (
  $db_name,
  $db_user,
  $install_dir                  = $title,
  $install_url                  = 'http://wordpress.org',
  $version                      = undef,
  $create_db                    = true,
  $create_db_user               = true,
  $db_host                      = 'localhost',
  $db_password                  = 'password',
  $wp_owner                     = 'root',
  $wp_group                     = '0',
  $wp_lang                      = '',
  $wp_config_content            = undef,
  $wp_plugin_dir                = 'DEFAULT',
  $wp_additional_config         = 'DEFAULT',
  $wp_table_prefix              = 'wp_',
  $wp_proxy_host                = '',
  $wp_proxy_port                = '',
  $wp_multisite                 = false,
  $wp_site_domain               = '',
  $wp_debug                     = false,
  $wp_debug_log                 = false,
  $wp_debug_display             = false,
  $wp_plugins                   = {},
  $wp_themes                    = {},
  $install_data_url             = undef,
  $install_data_title           = undef,
  $install_data_admin_user      = undef,
  $install_data_admin_password  = undef,
  $install_data_admin_email     = undef,
) {

  # Validations and checks
  validate_string($install_data_url, $install_data_title,
    $install_data_admin_user, $install_data_admin_password,
    $install_data_admin_email
  )
  $install_requested = pick_default($install_data_url, $install_data_title,
    $install_data_admin_user, $install_data_admin_password, $install_data_admin_email
  )
  $plugins_to_activate = $wp_plugins.filter |$k, $v| {
    has_key($v, 'activate') and validate_bool($v['activate']) and $v['activate']
  }
  $themes_to_activate = $wp_themes.filter |$k, $v| {
    has_key($v, 'activate') and validate_bool($v['activate']) and $v['activate']
  }
  if (!empty($plugins_to_activate) or !empty($themes_to_activate)) and
    $install_requested and ($install_data_url == undef or
    $install_data_title == undef or $install_data_admin_user == undef or
    $install_data_admin_password == undef or $install_data_admin_email == undef
  ) {
    fail('You must provide the five parameters to successfully install WordPress to activate plugins/themes: url, title, admin user, admin password and admin email')
  }

  # Resource defaults
  Exec {
    path      => ['/bin', '/sbin', '/usr/bin', '/usr/sbin', '/usr/local/bin'],
    logoutput => 'on_failure',
  }

  wordpress::instance::app { $install_dir:
    install_dir                  => $install_dir,
    install_url                  => $install_url,
    version                      => $version,
    db_name                      => $db_name,
    db_host                      => $db_host,
    db_user                      => $db_user,
    db_password                  => $db_password,
    wp_owner                     => $wp_owner,
    wp_group                     => $wp_group,
    wp_lang                      => $wp_lang,
    wp_config_content            => $wp_config_content,
    wp_plugin_dir                => $wp_plugin_dir,
    wp_additional_config         => $wp_additional_config,
    wp_table_prefix              => $wp_table_prefix,
    wp_proxy_host                => $wp_proxy_host,
    wp_proxy_port                => $wp_proxy_port,
    wp_multisite                 => $wp_multisite,
    wp_site_domain               => $wp_site_domain,
    wp_debug                     => $wp_debug,
    wp_debug_log                 => $wp_debug_log,
    wp_debug_display             => $wp_debug_display,
    install_data_url             => $install_data_url,
    install_data_title           => $install_data_title,
    install_data_admin_user      => $install_data_admin_user,
    install_data_admin_password  => $install_data_admin_password,
    install_data_admin_email     => $install_data_admin_email,
  }

  wordpress::instance::db { "${db_host}/${db_name}":
    create_db      => $create_db,
    create_db_user => $create_db_user,
    db_name        => $db_name,
    db_host        => $db_host,
    db_user        => $db_user,
    db_password    => $db_password,
  }

  $addons = {
    'plugin' => $wp_plugins,
    'theme'  => $wp_themes,
  }
  $addons.each |String $addon_type, Hash $col| {
    $col.each |String $slug, Hash $params| {
      $provider = pick_default($params['provider'], 'wpcli')
      wordpress::addon { "${title} > ${addon_type} ${slug}":
        slug           => $slug,
        type           => $addon_type,
        provider       => $provider,
        version        => $provider ? {
          'wpackagist' => pick_default($params['version'], '*'),
          'git'        => 'master',
          default      => $params['version'],
        },
        path           => pick_default($params['path'], $install_dir),
        owner          => pick_default($params['owner'], $wp_owner),
        group          => pick_default($params['group'], $wp_group),
        install        => $provider ? {
          'wpackagist' => undef,
          default      => has_key($params, 'install') ? {
            true       => $params['install'],
            default    => undef,
          },
        },
        activate       => has_key($params, 'activate') ? {
          true         => $params['activate'],
          default      => undef,
        },
        delete         => has_key($params, 'delete') ? {
          true         => $params['delete'],
          default      => undef,
        },
        source         => has_key($params, 'source') ? {
          true         => $params['source'],
          default      => undef,
        },
        notify         => Exec["Set ownership for ${install_dir}"],
        require        => $provider ? {
          'wpackagist' => Exec["Wpackagist ${install_dir}"],
          default      => Wordpress::Instance::App[$install_dir],
        },
      }
    }
  }

  wordpress::addon::wpackagist { $install_dir:
    path    => $install_dir,
    owner   => $wp_owner,
    group   => $wp_group,
    plugins => $wp_plugins.filter |$key, $value| {
      has_key($value, 'provider') and $value['provider'] == 'wpackagist'
    },
    themes  => $wp_themes.filter |$key, $value| {
      has_key($value, 'provider') and $value['provider'] == 'wpackagist'
    },
  }

  # Secure WordPress installation (but exclude internal folders)
  # For excludes see: http://stackoverflow.com/questions/4210042/exclude-directory-from-find-command/
  $excludes = sprintf('-not \( -path %s -prune \)', join($::wordpress::params::excludes, ' -prune \) -not \( -path '))
  exec { "Set ownership for ${install_dir}":
    cwd         => $install_dir,
    command     => "find . ${excludes} -exec chown ${wp_owner}:${wp_group} {} \\;",
    refreshonly => true,
    require     => [
      Wordpress::Addon[prefix(keys($wp_plugins), "${title} > plugin ")],
      Wordpress::Addon[prefix(keys($wp_themes), "${title} > theme ")],
      Wordpress::Instance::App[$install_dir],
      Wordpress::Instance::Db["${db_host}/${db_name}"]
    ],
    notify      => [
      Exec["Set folders access rights for ${install_dir}"],
      Exec["Set files access rights for ${install_dir}"],
      Exec["Prevent other users from reading ${install_dir}/wp-config.php"],
    ],
  }
  -> exec { "Set folders access rights for ${install_dir}":
    cwd         => $install_dir,
    command     => "find . ${excludes} -type d -exec chmod 755 {} \\;",
    refreshonly => true,
  }
  -> exec { "Set files access rights for ${install_dir}":
    cwd         => $install_dir,
    command     => "find . ${excludes} -type f -exec chmod 644 {} \\;",
    refreshonly => true,
  }
  # Permissions for wp-config.php should ideally be 600, but
  # maybe the owner and the webserver/php users aren't the same
  # Read: https://wordpress.org/support/topic/what-permission-do-you-suggest-for-wp-config
  -> exec { "Prevent other users from reading ${install_dir}/wp-config.php":
    cwd         => $install_dir,
    command     => "chmod 644 wp-config.php",
    refreshonly => true,
  }

}
