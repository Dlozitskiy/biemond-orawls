# == define: orawls::utils::orainst
#
#  creates oraInst.loc for oracle products
#
#
##
define orawls::utils::orainst
(
  $ora_inventory_dir = undef,
  $os_group          = undef,
  $orainstpath_dir   = hiera('orainstpath_dir', undef),
)
{
 
  if ( $orainstpath_dir == undef or $orainstpath_dir == '' ){
      $oraInstPath = '/etc'
     } else {
        $oraInstPath = $orainstpath_dir
     }

  if !defined(File["${oraInstPath}/oraInst.loc"]) {
    file { "${oraInstPath}/oraInst.loc":
      ensure  => present,
      content => template('orawls/utils/oraInst.loc.erb'),
      mode    => '0755',
    }
  }
}