# DB Fix 2 with even more
# fixiness!
#
#
# Database fix #1
#
# Boiler plate stuff for every firewall rule class
#
# IMPORTANT: set class name below to match file name.
# So rcc_firewalld::myclassname corresponds to manifests/myclassname.pp
#
class rcc_firewalld::database {
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

# End of IP Sets

  firewalld_rich_rule { 'SSH from rcc_networks':
    ensure  => present,
    zone    => 'rcczone',
    source  => { 'ipset'  => 'rcc_networks' },
    service =>  'ssh',
    action  => 'accept',
  }

  firewalld_rich_rule { 'mysql from rcc_networks':
    ensure  => present,
    zone    => 'rcczone',
    source  => { 'ipset'  => 'rcc_networks' },
    service =>  'mysql',
    action  => 'accept',
  }

  firewalld_rich_rule { 'Bacula-client from rcc_networks':
    ensure  => present,
    zone    => 'rcczone',
    source  => { 'ipset'  => 'rcc_networks' },
    service => 'bacula-client',
    action  => 'accept',
  }

  firewalld_rich_rule { 'ICMP from rcc_networks':
    ensure  => present,
    zone    => 'rcczone',
    source  => { 'ipset'  => 'rcc_networks' },
    protocol => 'icmp',
    action  => 'accept',
  }

}
