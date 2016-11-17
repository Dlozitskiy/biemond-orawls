# == Define: orawls::opatch
#
# installs oracle patches for Oracle products
#
##
define orawls::opatch(
  $ensure                  = 'present',  #present|absent
  $oracle_product_home_dir = undef, # /opt/oracle/middleware11gR1
  $jdk_home_dir            = hiera('wls_jdk_home_dir'), # /usr/java/jdk1.7.0_45
  $patch_id                = undef,
  $patch_file              = undef,
  $os_user                 = hiera('wls_os_user'), # oracle
  $os_group                = hiera('wls_os_group'), # dba
  $download_dir            = hiera('wls_download_dir'), # /data/install
  $source                  = hiera('opatch_source', undef), # puppet:///modules/orawls/ | /mnt | /vagrant
  $remote_file             = true,  # true|false
  $log_output              = false, # true|false
  $orainstpath_dir         = hiera('orainstpath_dir', undef),
  $temp_directory          = hiera('wls_temp_dir', undef),
)
{

  if $source == undef {
    $mountPoint = 'puppet:///modules/orawls/'
  } else {
    $mountPoint = $source
  }

  if $ensure == 'present' {
    if $remote_file == true {
      if ! defined(File["${download_dir}/${patch_file}"]) {
        file { "${download_dir}/${patch_file}":
          ensure => file,
          source => "${mountPoint}/${patch_file}",
          backup => false,
          mode   => '0775',
          owner  => $os_user,
          group  => $os_group,
          before => Wls_opatch["${oracle_product_home_dir}:${patch_id}"],
        }
      }
      $disk1_file = "${download_dir}/${patch_file}"
    } else {
      $disk1_file = "${source}/${patch_file}"
    }

      if ( $orainstpath_dir == undef or $orainstpath_dir == '' ){
        $oraInstPath = '/etc'
      } else {
        $oraInstPath = $orainstpath_dir
      }

  wls_opatch{"${oracle_product_home_dir}:${patch_id}":
    ensure       => $ensure,
    os_user      => $os_user,
    source       => $disk1_file,
    jdk_home_dir => $jdk_home_dir,
    orainst_dir  => $oraInstPath,
    tmp_dir      => $temp_directory,
  }

}