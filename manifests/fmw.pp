# == Define: orawls::fmw
#
# installs FMW software like ADF, FORMS, OIM, WC, WCC, OSB, SOA Suite, B2B, MFT
#
##
define orawls::fmw(
  $version              = hiera('wls_version', 12211),       # 1213|1221|12211
  $weblogic_home_dir    = hiera('wls_weblogic_home_dir'),    # /opt/oracle/middleware11gR1/wlserver_103
  $middleware_home_dir  = hiera('wls_middleware_home_dir'),  # /opt/oracle/middleware11gR1
  $oracle_base_home_dir = hiera('wls_oracle_base_home_dir'), # /opt/oracle
  $jdk_home_dir         = hiera('wls_jdk_home_dir'),         # /usr/java/jdk1.7.0_45
  $fmw_product          = undef,                             # adf|soa|soaqs|osb|wcc|wc|oim|oam|web|webgate|oud|mft|b2b|forms
  $fmw_file             = undef,
  $bpm                  = false,
  $os_user              = hiera('wls_os_user'),              # oracle
  $os_group             = hiera('wls_os_group'),             # dba
  $download_dir         = hiera('wls_download_dir'),         # /data/install
  $source               = hiera('wls_source', undef),        # puppet:///modules/orawls/ | /mnt | /vagrant
  $remote_file          = true,                              # true|false
  $log_output           = true,                              # true|false
  $temp_directory       = hiera('wls_temp_dir','/tmp'),      # /tmp directory
  $ohs_mode             = hiera('ohs_mode', 'collocated'),
  $oracle_inventory_dir = undef,
  $orainstpath_dir      = hiera('orainstpath_dir', undef),
)
{
  $exec_path    = "${jdk_home_dir}/bin:/usr/local/bin:/bin:/usr/bin:/usr/local/sbin:/usr/sbin:/sbin:"

  if $oracle_inventory_dir == undef {
    $oraInventory = "${oracle_base_home_dir}/oraInventory"
  } else {
    $oraInventory = $oracle_inventory_dir
  }

  if ( $orainstpath_dir == undef or $orainstpath_dir == '' ){
        $oraInstPath = '/etc'
      } 

  #Sanitise the resource title so that it can safely be used in filenames and execs
  #After converting all spaces to underscores, remove all non alphanumeric characters (allow hypens and underscores too)

  $convert_spaces_to_underscores = regsubst($title,'\s','_','G')
  $sanitised_title = regsubst ($convert_spaces_to_underscores,'[^a-zA-Z0-9_-]','','G')

  if ( $fmw_product == 'soa' ) {

    if $version >= 1221 {
      $total_files = 1
      $fmw_silent_response_file = 'orawls/fmw_silent_soa_1221.rsp.erb'
      $type                     = 'java'
      if $bpm == true {
        $install_type = 'BPM'
      } else {
        $install_type = 'SOA Suite'
      }
    }
    elsif $version == 1213 {
      $total_files = 1
      $fmw_silent_response_file = 'orawls/fmw_silent_soa_1213.rsp.erb'
      $type                     = 'java'
      if $bpm == true {
        $install_type = 'BPM'
      } else {
        $install_type = 'SOA Suite'
      }
    }

  } elsif ( $fmw_product == 'osb' ) {

    $total_files = 1
    if $version >= 1221 {
      $fmw_silent_response_file = 'orawls/fmw_silent_osb_1221.rsp.erb'
      $type                     = 'java'
    }
    elsif $version == 1213 {
      $fmw_silent_response_file = 'orawls/fmw_silent_osb_1213.rsp.erb'
      $type                     = 'java'
    }
  }
  
    orawls::utils::orainst { "create oraInst for ${name}":
      ora_inventory_dir => $oraInventory,
      os_group          => $os_group,
    }

    # Create response file

    file { "${download_dir}/${sanitised_title}_silent.rsp":
      ensure  => present,
      content => template($fmw_silent_response_file),
      mode    => '0775',
      owner   => $os_user,
      group   => $os_group,
      backup  => false,
      require => Orawls::Utils::Orainst["create oraInst for ${name}"],
    }

    # Download remote file

    if $remote_file == true {
      file { "${download_dir}/${fmw_file}":
        ensure => file,
        source => "${source}/${fmw_file}",
        mode   => '0775',
        owner  => $os_user,
        group  => $os_group,
        backup => false,
        require => Orawls::Utils::Orainst["create oraInst for ${name}"],
      }
      $disk1_file = "${download_dir}/${fmw_file}"
    } else {
      $disk1_file = "${source}/${fmw_file}"
    }

    # Prepre execution command line

    if $version >= 1221 {
      $command = "-silent -responseFile ${download_dir}/${sanitised_title}_silent.rsp"
    }
    else {
      $command = "-silent -response ${download_dir}/${sanitised_title}_silent.rsp -waitforcompletion"
    }

    # Prepre java command line options
 
    if $version == 1212 or $version == 1213 or $version >= 1221 {
    
        $install = "java -Djava.io.tmpdir=${temp_directory} -jar "
    
        # Install SOA

        if ( $fmw_product == 'soa' ) {

        exec { "install ${sanitised_title}":
        command     => "${install}${download_dir}/${fmw_file} ${command} -invPtrLoc ${oraInstPath}/oraInst.loc -ignoreSysPrereqs -jreLoc ${jdk_home_dir}",
        environment => "TEMP=${temp_directory}",
        timeout     => 0,
        creates     => "${middleware_home_dir}/soa",
        cwd         => $temp_directory,
        path        => $exec_path,
        user        => $os_user,
        group       => $os_group,
        logoutput   => $log_output,
        require     => [File["${download_dir}/${sanitised_title}_silent.rsp"],
                        Orawls::Utils::Orainst["create oraInst for ${name}"],
                        File["${download_dir}/${fmw_file}"],],
        } 
      } 

        # Install OSB

        elsif ( $fmw_product == 'osb' ) {

        exec { "install ${sanitised_title}":
        command     => "${install}${download_dir}/${fmw_file} ${command} -invPtrLoc ${oraInstPath}/oraInst.loc -ignoreSysPrereqs -jreLoc ${jdk_home_dir}",
        environment => "TEMP=${temp_directory}",
        timeout     => 0,
        creates     => "${middleware_home_dir}/osb",
        cwd         => $temp_directory,
        path        => $exec_path,
        user        => $os_user,
        group       => $os_group,
        logoutput   => $log_output,
        require     => [File["${download_dir}/${sanitised_title}_silent.rsp"],
                        Orawls::Utils::Orainst["create oraInst for ${name}"],
                        File["${download_dir}/${fmw_file}"],],

      }
     }
    }
  }
}