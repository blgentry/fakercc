# DNS Firewall fix #1
#
#
# It's fixed
#
#
# Boiler plate stuff for every firewall rule class
#
# IMPORTANT: set class name below to match file name.
# So rcc_firewalld::myclassname corresponds to manifests/myclassname.pp
#
class rcc_firewalld::dns {
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
    ensure  => present,
    path    => '/etc/firewalld/ipsets/rcc_networks.xml',
    source  => 'puppet:///modules/rcc_firewalld/ipsets/rcc_networks.xml',
    notify  => Service['firewalld'],
  }

  file {'katello':
    ensure  => present,
    path    => '/etc/firewalld/ipsets/katello.xml',
    source  => 'puppet:///modules/rcc_firewalld/ipsets/katello.xml',
    notify  => Service['firewalld'],
  }

# End of IP Sets

  firewalld_service { 'DNS from anywhere':
    ensure  => present,
    service => 'dns',
    zone    => 'rcczone',
  }

  firewalld_rich_rule { 'ANY from katello':
    ensure  => present,
    zone    => 'rcczone',
    source  => { 'ipset'  => 'katello' },
    action  => 'accept',
  }

  firewalld_rich_rule { 'SSH from rcc_networks':
    ensure  => present,
    zone    => 'rcczone',
    source  => { 'ipset'  => 'rcc_networks' },
    service => 'ssh',
    action  => 'accept',
  }

  firewalld_rich_rule { 'NTP from rcc_networks':
    ensure  => present,
    zone    => 'rcczone',
    source  => { 'ipset'  => 'rcc_networks' },
    service => 'ntp',
    action  => 'accept',
  }

# BLG 10/14/2019 Trying to get eroneous rejects on port 67
# to stop being logged.  
  firewalld_rich_rule { 'DHCP from rcc_networks':
    ensure  => present,
    zone    => 'rcczone',
    source  => { 'ipset'  => 'rcc_networks' },
    service => 'dhcp',
    action  => 'accept',
  }

  firewalld_rich_rule { 'ICMP from rcc_networks':
    ensure  => present,
    zone    => 'rcczone',
    source  => { 'ipset'  => 'rcc_networks' },
    protocol => 'icmp',
    action  => 'accept',
  }

  firewalld_rich_rule { 'Bacula from rcc_networks':
    ensure  => present,
    zone    => 'rcczone',
    source  => { 'ipset'  => 'rcc_networks' },
    service => 'bacula-client',
    action  => 'accept',
  }

}
