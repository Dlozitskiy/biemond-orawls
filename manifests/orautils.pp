# == Class: orawls::orautils
#

class orawls::orautils (
  $os_oracle_home            = $orawls::orautils::params::osOracleHome,
  $ora_inventory             = $orawls::orautils::params::oraInventory,
  $os_domain_type            = $orawls::orautils::params::osDomainType,
  $os_log_folder             = $orawls::orautils::params::osLogFolder,
  $os_download_folder        = $orawls::orautils::params::osDownloadFolder,
  $os_mdw_home               = $orawls::orautils::params::osMdwHome,
  $os_wl_home                = $orawls::orautils::params::osWlHome,
  $ora_user                  = $orawls::orautils::params::oraUser,
  $ora_group                 = $orawls::orautils::params::oraGroup,
  $os_domain                 = $orawls::orautils::params::osDomain,
  $os_domain_path            = $orawls::orautils::params::osDomainPath,
  $node_mgr_path             = $orawls::orautils::params::nodeMgrPath,
  $node_mgr_port             = $orawls::orautils::params::nodeMgrPort,
  $node_mgr_address          = $orawls::orautils::params::nodeMgrAddress,
  $wls_user                  = $orawls::orautils::params::wlsUser,
  $wls_password              = $orawls::orautils::params::wlsPassword,
  $wls_adminserver           = $orawls::orautils::params::wlsAdminServer,
  $jsse_enabled              = $orawls::orautils::params::jsseEnabled,
  $custom_trust              = false,
  $trust_keystore_file       = undef,
  $trust_keystore_passphrase = undef,
) inherits orawls::orautils::params
{

  case $::kernel {
    'Linux', 'SunOS': {

    $mode             = '0775'

    $shell            = $orawls::orautils::params::shell
    $userHome         = $orawls::orautils::params::userHome
    $oraInstHome      = $orawls::orautils::params::oraInstHome

    if $custom_trust == true {
      $trust_env = "-Dweblogic.security.TrustKeyStore=CustomTrust -Dweblogic.security.CustomTrustKeyStoreFileName=${trust_keystore_file} -Dweblogic.security.CustomTrustKeystorePassPhrase=${trust_keystore_passphrase}"
    } else {
      $trust_env = ''
    }

    if ! defined(File['/opt/scripts']) {
      file { '/opt/scripts':
        ensure  => directory,
        recurse => false,
        replace => false,
        owner   => $ora_user,
        group   => $ora_group,
        mode    => $mode,
      }
    }

    if ! defined(File['/opt/scripts/wls']) {
      file { '/opt/scripts/wls':
        ensure  => directory,
        recurse => false,
        replace => false,
        owner   => $ora_user,
        group   => $ora_group,
        mode    => $mode,
        require => File['/opt/scripts'],
      }
    }

    file { 'showStatus.sh':
      ensure  => present,
      path    => '/opt/scripts/wls/showStatus.sh',
      content => regsubst(template('orawls/wls/showStatus.sh.erb'), '\r\n', "\n", 'EMG'),
      owner   => $ora_user,
      group   => $ora_group,
      mode    => $mode,
      require => File['/opt/scripts/wls'],
    }

    file { 'stopNodeManager.sh':
      ensure  => present,
      path    => '/opt/scripts/wls/stopNodeManager.sh',
      content => regsubst(template('orawls/wls/stopNodeManager.sh.erb'), '\r\n', "\n", 'EMG'),
      owner   => $ora_user,
      group   => $ora_group,
      mode    => $mode,
      require => File['/opt/scripts/wls'],
    }

    file { 'cleanOracleEnvironment.sh':
      ensure  => present,
      path    => '/opt/scripts/wls/cleanOracleEnvironment.sh',
      content => regsubst(template('orawls/cleanOracleEnvironment.sh.erb'), '\r\n', "\n", 'EMG'),
      owner   => 'root',
      group   => 'root',
      mode    => '0770',
      require => File['/opt/scripts/wls'],
    }

    file { 'startNodeManager.sh':
      ensure  => present,
      path    => '/opt/scripts/wls/startNodeManager.sh',
      content => regsubst(template('orawls/startNodeManager.sh.erb'), '\r\n', "\n", 'EMG'),
      owner   => $ora_user,
      group   => $ora_group,
      mode    => $mode,
      require => File['/opt/scripts/wls'],
    }

    file { 'startWeblogicAdmin.sh':
      ensure  => present,
      path    => '/opt/scripts/wls/startWeblogicAdmin.sh',
      content => regsubst(template('orawls/startWeblogicAdmin.sh.erb'), '\r\n', "\n", 'EMG'),
      owner   => $ora_user,
      group   => $ora_group,
      mode    => $mode,
      require => File['/opt/scripts/wls'],
    }

    file { 'stopWeblogicAdmin.sh':
      ensure  => present,
      path    => '/opt/scripts/wls/stopWeblogicAdmin.sh',
      content => regsubst(template('orawls/stopWeblogicAdmin.sh.erb'), '\r\n', "\n", 'EMG'),
      owner   => $ora_user,
      group   => $ora_group,
      mode    => $mode,
      require => File['/opt/scripts/wls'],
    }

    }
    default: {
      notify{'This operating system is not supported':}
    }
  }
}
