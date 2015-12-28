define wordpress::instance::app (
  $install_dir,
  $install_url,
  $version,
  $db_name,
  $db_host,
  $db_user,
  $db_password,
  $wp_owner,
  $wp_group,
  $wp_lang,
  $wp_config_content,
  $wp_plugin_dir,
  $wp_additional_config,
  $wp_table_prefix,
  $wp_proxy_host,
  $wp_proxy_port,
  $wp_multisite,
  $wp_site_domain,
  $wp_debug,
  $wp_debug_log,
  $wp_debug_display,
  $install_data_url             = undef,
  $install_data_title           = undef,
  $install_data_admin_user      = undef,
  $install_data_admin_password  = undef,
  $install_data_admin_email     = undef,
) {
  validate_string($install_dir, $install_url, $version, $db_name, $db_host,
    $db_user, $db_password, $wp_owner, $wp_group, $wp_lang, $wp_plugin_dir,
    $wp_additional_config, $wp_table_prefix, $wp_proxy_host, $wp_proxy_port,
    $wp_site_domain, $install_data_url, $install_data_title,
    $install_data_admin_user, $install_data_admin_password,
    $install_data_admin_email
  )
  validate_bool($wp_multisite, $wp_debug, $wp_debug_log, $wp_debug_display)
  validate_absolute_path($install_dir)

  if $wp_config_content and ($wp_lang or $wp_debug or $wp_debug_log or
    $wp_debug_display or $wp_proxy_host or $wp_proxy_port or
    $wp_multisite or $wp_site_domain
  ) {
    warning('When $wp_config_content is set, the following parameters are ignored: $wp_table_prefix, $wp_lang, $wp_debug, $wp_debug_log, $wp_debug_display, $wp_plugin_dir, $wp_proxy_host, $wp_proxy_port, $wp_multisite, $wp_site_domain, $wp_additional_config')
  }

  if $wp_multisite and ! $wp_site_domain {
    fail('wordpress class requires `wp_site_domain` parameter when `wp_multisite` is true')
  }

  if $wp_debug_log and ! $wp_debug {
    fail('wordpress class requires `wp_debug` parameter to be true, when `wp_debug_log` is true')
  }

  if $wp_debug_display and ! $wp_debug {
    fail('wordpress class requires `wp_debug` parameter to be true, when `wp_debug_display` is true')
  }
  
  $install_requested = pick_default($install_data_url, $install_data_title,
    $install_data_admin_user, $install_data_admin_password, $install_data_admin_email
  )
  if $install_requested != undef and ($install_data_url == undef or
    $install_data_title == undef or $install_data_admin_user == undef or
    $install_data_admin_password == undef or $install_data_admin_email == undef
  ) {
    fail('You must provide the five parameters to successfully install WordPress: url, title, admin user, admin password and admin email')
  } else {
    include wordpress::wpcli
  }

  ## Resource defaults
  File {
    owner  => $wp_owner,
    group  => $wp_group,
    mode   => '0644',
  }
  Exec {
    path      => ['/bin', '/sbin', '/usr/bin', '/usr/sbin', '/usr/local/bin'],
    logoutput => 'on_failure',
  }

  $filename = $version ? {
    undef   => 'latest',
    default => "wordpress-${version}",
  }

  ## Installation directory
  exec { "Create install dir ${install_dir}":
    command => "mkdir -p ${install_dir}",
    unless  => "test -d ${install_dir}",
    before  => Exec["Download wordpress ${install_url}/${filename}.tar.gz to ${install_dir}"],
  }
  # Target folder must be writable to download and extract tar
  -> file { $install_dir:
    ensure  => directory,
    owner   => $wp_owner,
    group   => $wp_group,
    mode    => '0755',
  }

  ## Download and extract
  $notify = $filename ? {
    'latest' => [
      Exec["Set ownership for ${install_dir}"],
      Exec["Remove tarball ${install_dir}/${filename}.tar.gz"],
    ],
    default  => Exec["Set ownership for ${install_dir}"],
  }
  exec { "Download wordpress ${install_url}/${filename}.tar.gz to ${install_dir}":
    command => "wget ${install_url}/${filename}.tar.gz",
    creates => "${install_dir}/${filename}.tar.gz",
    require => Exec["Create install dir ${install_dir}"],
    user    => $wp_owner,
    group   => $wp_group,
    cwd     => $install_dir,
    notify  => $notify,
  }
  -> exec { "Extract wordpress ${install_dir}":
    command => "tar zxvf ./${filename}.tar.gz --strip-components=1",
    creates => "${install_dir}/index.php",
    user    => $wp_owner,
    group   => $wp_group,
    cwd     => $install_dir,
  }
  exec { "Remove tarball ${install_dir}/${filename}.tar.gz":
    command     => "rm -f ${install_dir}/${filename}.tar.gz",
    onlyif      => "test -f ${install_dir}/${filename}.tar.gz",
    refreshonly => true,
  }

  ## Configure wordpress
  #
  concat { "${install_dir}/wp-config.php":
    owner   => $wp_owner,
    group   => $wp_group,
    require => Exec["Extract wordpress ${install_dir}"],
  }
  if $wp_config_content {
    concat::fragment { "${install_dir}/wp-config.php body":
      target  => "${install_dir}/wp-config.php",
      content => $wp_config_content,
      order   => '20',
    }
  } else {
    # Template uses no variables
    file { "${install_dir}/wp-keysalts.php":
      ensure  => present,
      content => template('wordpress/wp-keysalts.php.erb'),
      replace => false,
      require => Exec["Extract wordpress ${install_dir}"],
    }
    concat::fragment { "${install_dir}/wp-config.php keysalts":
      target  => "${install_dir}/wp-config.php",
      source  => "${install_dir}/wp-keysalts.php",
      order   => '10',
      require => File["${install_dir}/wp-keysalts.php"],
    }
    # Template uses:
    # - $db_name
    # - $db_user
    # - $db_password
    # - $db_host
    # - $wp_table_prefix
    # - $wp_lang
    # - $wp_plugin_dir
    # - $wp_proxy_host
    # - $wp_proxy_port
    # - $wp_multisite
    # - $wp_site_domain
    # - $wp_additional_config
    # - $wp_debug
    # - $wp_debug_log
    # - $wp_debug_display
    concat::fragment { "${install_dir}/wp-config.php body":
      target  => "${install_dir}/wp-config.php",
      content => template('wordpress/wp-config.php.erb'),
      order   => '20',
    }
  }

  ## Install WordPress
  #
  $install_flags = [
    "--path=\"${install_dir}\"",
    "--url=\"${install_data_url}\"",
    "--title=\"${install_data_title}\"",
    "--admin_user=\"${install_data_admin_user}\"",
    "--admin_password=\"${install_data_admin_password}\"",
    "--admin_email=\"${install_data_admin_email}\"",
  ]
  $cmd_options = $install_flags.join(' ')
  if $install_requested {
    exec { "wp core install ${cmd_options}":
      unless  => "wp core is-installed --path=${install_dir}",
      user    => $wp_owner,
      group   => $wp_group,
      require => [
        Class['wordpress::wpcli'],
        Concat::Fragment["${install_dir}/wp-config.php body"],
        Concat["${install_dir}/wp-config.php"],
      ],
    }
  }

}
