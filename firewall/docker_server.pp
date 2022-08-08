# Boiler plate stuff for every firewall rule class
#
# IMPORTANT: set class name below to match file name.
# So rcc_firewalld::myclassname corresponds to manifests/myclassname.pp
#
class rcc_firewalld::docker_server {
  class { '::firewalld':
    default_zone => 'rcczone',
    log_denied   => 'all',
  }
  firewalld_zone { 'rcczone':
    ensure           => present,
    target           => '%%REJECT%%',
    purge_rich_rules => true,
    purge_services   => true,
    purge_ports      => true,
  }

# End of boiler plate

# Files to define IP Sets

  file {'rcc_networks':
    ensure => present,
    path   => '/etc/firewalld/ipsets/rcc_networks.xml',
    source => 'puppet:///modules/rcc_firewalld/ipsets/rcc_networks.xml',
    notify => Service['firewalld'],
  }

  file {'fsu_networks':
    ensure => present,
    path   => '/etc/firewalld/ipsets/fsu_networks.xml',
    source => 'puppet:///modules/rcc_firewalld/ipsets/fsu_networks.xml',
    notify => Service['firewalld'],
  }

# End of IP Sets

  firewalld_rich_rule { 'SSH from rcc_networks':
    ensure  => present,
    zone    => 'rcczone',
    source  => { 'ipset'  => 'rcc_networks' },
    service => 'ssh',
    action  => 'accept',
  }

  firewalld_rich_rule { 'Docker Port 2375 from rcc_networks':
    ensure => present,
    zone   => 'rcczone',
    source => { 'ipset' => 'rcc_networks' },
    port   => {
      'port'     => 2375,
      'protocol' => 'tcp',
    },
    action => 'accept',
  }
}
