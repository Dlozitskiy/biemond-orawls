# == Class: orawls::os
#
class orawls::os (
  $os_user              = 'oracle',              
  $os_group             = 'oinstall',
  $os_user_home			= '/home/oracle',
  $os_user_password		= '$1$bgksg0Bc$gDICOuUpCl59noe0BZ5Y71',
  $os_bin_root			= '/u01',
  $os_packages			= ['binutils.x86_64','unzip.x86_64'],
  $os_packages_rm		= ['java-1.7.0-openjdk.x86_64','java-1.6.0-openjdk.x86_64'],
  $os_ssh_source		= undef,

) {
 
# Ensure that internal Linux Firewall (iptables) is disabled

  service { iptables:
        enable    => false,
        ensure    => false,
        hasstatus => true,
  }

# Ensure that the OS group exists on the Linux Server

  group { $os_group:
    ensure => present,
  }

# Ensure that the OS user exists on the Linux Server

  user { $os_user:
    ensure     => present,
    groups     => $os_group,
    shell      => '/bin/bash',
    password   => $os_user_password,
    home       => $os_user_home,
    managehome => true,
    require    => Group[$os_group],
  }

# Install required OS packages for OFM

  package { $os_packages:
    ensure  => present,
  }

# Remove any conflicts packages

  package { $os_packages_rm:
    ensure  => absent,
  }

# Create parent folder

   file { ["${os_bin_root}"]:
    owner  => $os_user,
    group  => $os_group,
    mode   => "775",
    ensure => "directory",
   }

# Download SSH keys for user

   file { "${os_user_home}/.ssh/":
    owner  => $os_user,
    group  => $os_group,
    mode   => "700",
    ensure => "directory",
    alias  => "ssh-dir",
   }

   file { "${os_user_home}/.ssh/id_rsa.pub":
     ensure  => present,
     owner   => $os_user,
     group   => $os_group,
     mode    => "644",
     source  => "${os_ssh_source}/${os_user}_id_rsa.pub",
     require => File["ssh-dir"],
   }

   file { "${os_user_home}/.ssh/id_rsa":
     ensure  => present,
     owner   => $os_user,
     group   => $os_group,
     mode    => "600",
     source  => "${os_ssh_source}/${os_user}_id_rsa",
     require => File["ssh-dir"],
   }

   file { "${os_user_home}/.ssh/authorized_keys":
     ensure  => present,
     owner   => $os_user,
     group   => $os_group,
     mode    => "644",
     source  => "${os_ssh_source}/${os_user}_authorized_keys",
     require => File["ssh-dir"],
   }

}