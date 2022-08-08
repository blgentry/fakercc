#

# Valid roles are:
#  'quorum' = [ Admin and client-quorum nodes ]
#  'client' = [ All non-quorum GPFS clients ]
#  'ces' = [ All CES GPFS nodes ]
#
# Valid mount options are:
#  'true'   = [ Start service and mount volume(s) ]
#  'false'  = [ Stopt service and un-mount volume(s) ]
#
class rcc_gpfs (
  $role = 'client',
  $ensure_mnt = true,
) {

  if $ensure_mnt == true { $svc_ensure = 'running' }

  # temporary hack
  # remove when all clients have been upgraded
  # GPFS UPGRADE DAY: set export nodes to 4.2 but default to 5.0
  $gpfs_ver = $hostname ? {
    default          => '5.0.5-1.3',
  }

  $gpfs_gplbin_kern_ver = $::kernelrelease ? {
    '3.10.0-514.el7.x86_64'      => "gpfs.gplbin-3.10.0-514.el7.x86_64-${gpfs_ver}",
    '3.10.0-514.16.1.el7.x86_64' => "gpfs.gplbin-3.10.0-514.16.1.el7.x86_64-${gpfs_ver}",
    '3.10.0-514.26.2.el7.x86_64' => "gpfs.gplbin-3.10.0-514.26.2.el7.x86_64-${gpfs_ver}",
    '3.10.0-693.el7.x86_64'      => "gpfs.gplbin-3.10.0-693.el7.x86_64-${gpfs_ver}",
    '3.10.0-693.21.1.el7.x86_64' => "gpfs.gplbin-3.10.0-693.21.1.el7.x86_64-${gpfs_ver}",
    '4.18.0-240.15.1.el8_3.x86_64' => "gpfs.gplbin-4.18.0-240.15.1.el8_3.x86_64-${gpfs_ver}",
    '4.18.0-240.el8.x86_64' => "gpfs.gplbin-4.18.0-240.15.1.el8_3.x86_64-${gpfs_ver}",
    # make sure that we have something that is always installed
    # so we don't break puppet (yeah this can be done smarter)
    default                      => 'kernel',  
  }

  $gpfs_base_ver = "gpfs.base-${gpfs_ver}"
  $gpfs_gskit_ver = $gpfs_ver ? {
    '4.2.3-5'   => 'gpfs.gskit-8.0.50-75',
    '5.0.4-4' => 'gpfs.gskit-8.0.50-86',
    '5.0.5-1.3' => 'gpfs.gskit-8.0.55-12'
  }

  #package {'gpfs.gss.pmsensors': ensure => installed,}
  package {
    [
    $gpfs_base_ver,
    $gpfs_gskit_ver,
    'gpfs.gss.pmsensors',
    $gpfs_gplbin_kern_ver,
    ]:
    ensure      => installed,
    require     => Exec['hpc_software_pub_key'],
  }
  if $role == 'quorum' {
    package {
      [
      "gpfs.docs-${gpfs_ver}",
      ]:
      ensure      => present,
      require     => Exec['hpc_software_pub_key'],
    }
  }
  elsif $role == 'ces' {
    package {
      [
      'lsof',
      'gpfs.ext',
      'nfs-ganesha-2.3.2-0.ibm67.el7',
      'nfs-ganesha-gpfs-2.3.2-0.ibm67.el7',
      'nfs-ganesha-utils-2.3.2-0.ibm67.el7',
      'openldap-clients',
      ]:
      ensure      => present,
      require     => Exec['hpc_software_pub_key'],
    }
    file {'/var/mmfs/ces/nfs-config':
      ensure	=> 'directory',
      require   => Package['nfs-ganesha-gpfs-2.3.2-0.ibm67.el7'],
    }
    file {'/etc/ganesha/ganesha.conf':
      ensure	=> 'link',
      target	=> '/etc/ganesha/gpfs.ganesha.nfsd.conf',
      require   => File['ganesha_nfsd_cfg'],
    }
    file {'ganesha_exports_cfg':
      path	=> '/etc/ganesha/gpfs.ganesha.exports.conf',
      source	=> 'puppet:///modules/rcc_gpfs/gpfs.ganesha.exports.conf',
      require   => Package['nfs-ganesha-2.3.2-0.ibm67.el7'],
      notify	=> Service['nfs-ganesha'],
    }
    file {'ganesha_log_cfg':
      path	=> '/etc/ganesha/gpfs.ganesha.log.conf',
      source	=> 'puppet:///modules/rcc_gpfs/gpfs.ganesha.log.conf',
      require   => Package['nfs-ganesha-2.3.2-0.ibm67.el7'],
      notify	=> Service['nfs-ganesha'],
    }
    file {'ganesha_main_cfg':
      path	=> '/etc/ganesha/gpfs.ganesha.main.conf',
      source	=> 'puppet:///modules/rcc_gpfs/gpfs.ganesha.main.conf',
      require   => Package['nfs-ganesha-2.3.2-0.ibm67.el7'],
      notify	=> Service['nfs-ganesha'],
    }
    file {'ganesha_nfsd_cfg':
      path	=> '/etc/ganesha/gpfs.ganesha.nfsd.conf',
      source	=> 'puppet:///modules/rcc_gpfs/gpfs.ganesha.nfsd.conf',
      require   => Package['nfs-ganesha-2.3.2-0.ibm67.el7'],
      notify	=> Service['nfs-ganesha'],
    }
    service { 'nfs-ganesha':
      ensure      => $svc_ensure,
      enable      => false,
      hasrestart  => true,
      hasstatus   => true,
      require     => [ Exec['gpfs_mount'], Package['nfs-ganesha-2.3.2-0.ibm67.el7'], Service['gpfs'], File['ganesha_nfsd_cfg'] ],
    }
  }

  service { 'gpfs':
    ensure      => $svc_ensure,
    enable      => true,
    hasrestart  => true,
    hasstatus   => true,
    require     => [ Package[$gpfs_base_ver], Service['chronyd'], Exec['gpfs_startup'] ],
  }
  service { 'pmsensors':
    ensure     => running,
    enable     => true,
    hasstatus  => true,
    hasrestart => true,
    require    => [Package['gpfs.gss.pmsensors'], File['/opt/IBM/zimon/ZIMonSensors.cfg']],
  }

  file { '/opt/IBM/zimon/ZIMonSensors.cfg':
    content    => template('rcc_gpfs/ZIMonSensors.cfg.erb'),
    notify     => Service['pmsensors'],
    require    => Package['gpfs.gss.pmsensors'],
  }

  file { '/var/log/gpfs/':
    ensure	=> link,
    target	=> '/var/adm/ras/',
  }

  #$? to get value
  exec { 'gpfs_startup':
    command => 'mmstartup',
    path    => '/bin:/sbin:/usr/lpp/mmfs/bin/',
    unless  => ['lsmod | grep mmfs'],
    #unless  => ['lsmod | grep mmfs',"mmlscluster | grep ${::fqdn}"],
    timeout => 300,
    require => [ Package[$gpfs_base_ver], Package[$gpfs_gplbin_kern_ver] ]
  }

  #Don't run the following code if we don't need the mount right now
  if $ensure_mnt == true {
    # Gives the service time to start before doing gpfs_mount
    exec { 'gpfs_sleep':
      command => 'sleep 10',
      path    => '/bin/',
      returns => ['0'],
      timeout => 30,
      unless  => ['test -d /gpfs/research/system'],
      require => [ Exec['gpfs_startup'], Service['gpfs'] ]
    }

    exec { 'gpfs_mount':
      command => 'mmmount all',
      path    => '/usr/lpp/mmfs/bin/',
      creates => '/gpfs/research/system',
      returns => ['0'],
      timeout => 300,
      require => [ Exec['gpfs_startup'], Exec['gpfs_sleep'], Service['gpfs'] ]
    }
  }

  ## GPFS Callbacks below--------
  ## https://zeronixo.blogspot.com/2013/07/gpfs-exercise-5-creating-callback.html
  file {'/callbacks': ensure		=> 'directory', }
  file {'/callbacks/log': ensure	=> 'directory', }
  file {'/callbacks/nodedown.ksh':
    ensure	=> present,
    mode	=> '0755',
    source	=> 'puppet:///modules/rcc_gpfs/callbacks/nodedown.ksh',
    require	=> Package[$gpfs_base_ver],
  }
  file {'/callbacks/nodestartup.ksh':
    ensure	=> present,
    mode	=> '0755',
    source	=> 'puppet:///modules/rcc_gpfs/callbacks/nodestartup.ksh',
    require	=> Package[$gpfs_base_ver],
  }
  ## Create the callback *MANUALLY* witht he follwoing command on ADMIN
  # mmaddcallback NodeShutDown --command /callbacks/nodedown.ksh --event shutdown --parms %eventNode --parms %quorumNodes
  # mmaddcallback NodeStartUp --command /callbacks/nodestartup.ksh --event startup
  ## Test the CallBack with the following command on ADMIN
  # mmlscallback
}

