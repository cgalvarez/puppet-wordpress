class wordpress::params {
  $_module_defaults = {
    'install_dir'           => '/opt/wordpress',
    'install_url'           => 'http://wordpress.org',
    'version'               => undef,
    'create_db'             => true,
    'create_db_user'        => true,
    'db_name'               => 'wordpress',
    'db_host'               => 'localhost',
    'db_user'               => 'wordpress',
    'db_password'           => 'password',
    'wp_owner'              => 'root',
    'wp_group'              => '0',
    'wp_lang'               => '',
    'wp_config_content'     => undef,
    'wp_plugin_dir'         => 'DEFAULT',
    'wp_additional_config'  => 'DEFAULT',
    'wp_table_prefix'       => 'wp_',
    'wp_proxy_host'         => '',
    'wp_proxy_port'         => '',
    'wp_multisite'          => false,
    'wp_site_domain'        => '',
    'wp_debug'              => false,
    'wp_debug_log'          => false,
    'wp_debug_display'      => false,
  }
  case $::osfamily {
    default: {
      ## For cases not covered in $::osfamily
      case $::operatingsystem {
        default: {
          $_module_os_overrides = {}
        }
      }
    }
  }
  $_instance_defaults = merge($_module_defaults, $_module_os_overrides)
  $excludes = [
      '.git',
      'bower_components',
      'node_modules',
      'vendor',
    ]

  ### Referenced Variables
  $install_dir          = $_instance_defaults['install_dir']
  $install_url          = $_instance_defaults['install_url']
  $version              = $_instance_defaults['version']
  $create_db            = $_instance_defaults['create_db']
  $create_db_user       = $_instance_defaults['create_db_user']
  $db_name              = $_instance_defaults['db_name']
  $db_host              = $_instance_defaults['db_host']
  $db_user              = $_instance_defaults['db_user']
  $db_password          = $_instance_defaults['db_password']
  $wp_owner             = $_instance_defaults['wp_owner']
  $wp_group             = $_instance_defaults['wp_group']
  $wp_lang              = $_instance_defaults['wp_lang']
  $wp_config_content    = $_instance_defaults['wp_config_content']
  $wp_plugin_dir        = $_instance_defaults['wp_plugin_dir']
  $wp_additional_config = $_instance_defaults['wp_additional_config']
  $wp_table_prefix      = $_instance_defaults['wp_table_prefix']
  $wp_proxy_host        = $_instance_defaults['wp_proxy_host']
  $wp_proxy_port        = $_instance_defaults['wp_proxy_port']
  $wp_multisite         = $_instance_defaults['wp_multisite']
  $wp_site_domain       = $_instance_defaults['wp_site_domain']
  $wp_debug             = $_instance_defaults['wp_debug']
  $wp_debug_log         = $_instance_defaults['wp_debug_log']
  $wp_debug_display     = $_instance_defaults['wp_debug_display']
  ### END Referenced Variables
}
