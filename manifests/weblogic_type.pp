# rewrite of Class: orawls::weblogic as defined type so multiple installation of product will be possible on single host
#
define orawls::weblogic_type (
  $version              = 1111,  # 1036|1111|1211|1212|1213|1221|12211
  $filename             = undef, # wls1036_generic.jar|wls1211_generic.jar|wls_121200.jar|wls_121300.jar|oepe-wls-indigo-installer-11.1.1.8.0.201110211138-10.3.6-linux32.bin
  $oracle_base_home_dir = undef, # /opt/oracle
  $middleware_home_dir  = undef, # /opt/oracle/middleware11gR1
  $weblogic_home_dir    = undef, # /opt/oracle/middleware11gR1/wlserver
  $wls_domains_dir      = hiera('wls_domains_dir', undef), # /opt/oracle/wlsdomains/domains
  $wls_apps_dir         = hiera('wls_apps_dir', undef), # /opt/oracle/wlsdomains/applications
  $fmw_infra            = false, # true|false 1212/1213/1221 option -> plain weblogic or fmw infra
  $jdk_home_dir         = undef, # /usr/java/jdk1.7.0_45
  $os_user              = undef, # oracle
  $os_group             = undef, # dba
  $download_dir         = undef, # /data/install
  $source               = undef, # puppet:///modules/orawls/ | /mnt | /vagrant
  $remote_file          = true,  # true|false
  $java_parameters      = '',    # '-Dspace.detection=false'
  $log_output           = false, # true|false
  $validation           = true,  # true|false
  $force                = false, # true|false
  $temp_directory       = '/tmp',# /tmp temporay directory for files extractions
  $orainstpath_dir      = hiera('orainstpath_dir', undef),
) {

  # check required parameters
  if ( $filename == undef or $oracle_base_home_dir == undef or $middleware_home_dir == undef or $jdk_home_dir == undef or $os_user == undef or $os_group == undef or $download_dir == undef ) {
    fail('please provide all the required parameters')
  }

   if ( $fmw_infra == true ) {
    $install_type='Fusion Middleware Infrastructure'
   } else {
    $install_type='WebLogic Server'
   }
  
  if $version >= 1221 {
    $new_version = 1221
  } else {
    $new_version = $version
  }
  
  $silent_template = "orawls/weblogic_silent_install_${new_version}.rsp.erb"

  $exec_path         = "${jdk_home_dir}/bin:/usr/local/bin:/bin:/usr/bin:/usr/local/sbin:/usr/sbin:/sbin:"
  $ora_inventory_dir = "${oracle_base_home_dir}/oraInventory"

  Exec {
    logoutput => $log_output,
  }

  if ( $orainstpath_dir == undef or $orainstpath_dir == '' ){
    $oraInstPath = '/etc'
  } else {
    $oraInstPath = $orainstpath_dir
  }

  $java_statement     = "java ${java_parameters}"
    
  if $source == undef {
    $mountPoint = 'puppet:///modules/orawls/'
  } else {
    $mountPoint = $source
  }

  $file_ext = regsubst($filename, '.*(\.jar)$', '\1')

  if $file_ext == '.jar' {
    $jar_file = true
  } else {
    $jar_file = false
  }

  if $jar_file {
    $cmd_prefix = "${java_statement} -Xmx1024m -Djava.io.tmpdir=${temp_directory} -jar "
  } else {
    $cmd_prefix = ''
  }

  if $remote_file == true {
    $weblogic_jar_location = "${download_dir}/${filename}"
  } else {
    $weblogic_jar_location = "${source}/${filename}"
  }

  if $validation == false {
    $validation_string = '-novalidation'
  } else {
    $validation_string = ''
  }

  if $force == true {
    $force_string = '-force'
  } else {
    $force_string = ''
  }

  $oraInventory  = "${oracle_base_home_dir}/oraInventory"

  orawls::utils::orainst { "weblogic orainst ${title}":
    ora_inventory_dir => $oraInventory,
    os_group          => $os_group,
  }

#  wls_directory_structure{"weblogic structure ${title}":
#    ensure                => present,
#    oracle_base_dir       => $oracle_base_home_dir,
#    ora_inventory_dir     => $ora_inventory_dir,
#    download_dir          => $download_dir,
#    wls_domains_dir       => $domains_dir,
#    wls_apps_dir          => $apps_dir,
#    os_user               => $os_user,
#    os_group              => $os_group,
#  }

  file { ["${oracle_base_home_dir}","${middleware_home_dir}","${wls_domains_dir}","${wls_apps_dir}"]:
    owner  => $os_user,
    group  => $os_group,
    mode   => "775",
    ensure => "directory",
  }

  # for performance reasons, download and install or just install it
  if $remote_file == true {
    # put weblogic generic jar
    file { "${download_dir}/${filename}":
      ensure  => file,
      source  => "${mountPoint}/${filename}",
      replace => false,
      backup  => false,
      mode    => '0775',
      owner   => $os_user,
      group   => $os_group,
      before  => Exec["install weblogic ${title}"],
      require => Wls_directory_structure["weblogic structure ${title}"],
    }
  }

  # de xml used by the wls installer
  file { "${download_dir}/weblogic_silent_install_${title}.xml":
    ensure  => present,
    content => template($silent_template),
    replace => true,
    mode    => '0775',
    owner   => $os_user,
    group   => $os_group,
    backup  => false,
    require => Wls_directory_structure["weblogic structure ${title}"],
  }

  # if weblogic home dir is specified then check that for creates
  if ( $weblogic_home_dir != undef ) {
    $created_dir = $weblogic_home_dir
  } else {
    $created_dir = $middleware_home_dir
  }

  $command = "-silent -responseFile ${download_dir}/weblogic_silent_install_${title}.xml ${validation_string} ${force_string} "

    # notify { "install weblogic ${version}: ${exec_path}": }
  exec { "install weblogic ${title}":
    command     => "${cmd_prefix}${weblogic_jar_location} ${command} -invPtrLoc ${oraInstPath}/oraInst.loc -ignoreSysPrereqs",
    environment => ['JAVA_VENDOR=Sun', "JAVA_HOME=${jdk_home_dir}"],
    timeout     => 0,
    creates     => "${created_dir}/wlserver",
    path        => $exec_path,
    user        => $os_user,
    group       => $os_group,
    require     => [Wls_directory_structure["weblogic structure ${title}"],
                   Orawls::Utils::Orainst["weblogic orainst ${title}"],
                   File["${download_dir}/weblogic_silent_install_${title}.xml"]],
  }

}
