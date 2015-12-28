# Class: wordpress::wpcli
#
# This module manages WPCLI installation
#
# Parameters:
#
# There are no default parameters for this class.
#
# Actions:
#
# Requires:
#
# Sample Usage:
#
# This class file is not called directly
class wordpress::wpcli(
  $ensure = 'present',
) {

  validate_string($ensure)
  validate_re($ensure, '^(present|installed|latest|absent|purged)$',
    "${ensure} is not supported for \$ensure. Allowed values are 'present', 'installed', 'latest', 'purged' and 'absent'.")

  $wpcli = 'wp-cli.phar'
  $wpcli_exec = '/usr/local/bin/wp'

  # Download, move to bin path and set permissions/ownership
  exec { "curl -O https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/${wpcli} && mv ${wpcli} ${wpcli_exec}":
    path    => '/bin:/usr/bin:/sbin:/usr/sbin:/usr/local/bin',
    creates => $wpcli_exec,
    before  => File[$wpcli_exec],
  }
  file { $wpcli_exec:
    mode   => '0755',
    owner  => 'root',
    ensure => $ensure ? {
      'absent' => 'absent',
      'purged' => 'absent',
      default  => 'file',
    }
  }

}
