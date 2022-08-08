# Boiler plate stuff for every firewall rule class
#
# IMPORTANT: set class name below to match file name.
# So rcc_firewalld::myclassname corresponds to manifests/myclassname.pp
#
class rcc_firewalld::demo {
  class { '::firewalld':
    default_zone => 'rcczone',
  }
  firewalld_zone { 'rcczone':
    ensure           => present,
    target           => '%%REJECT%%',
    purge_rich_rules => true,
    purge_services   => true,
    purge_ports      => true,
  }

# End of boiler plate

  firewalld_ipset { 'fsu_networks':
    ensure => present,
    entries => ['10.0.0.0/8','128.186.0.0/16','146.201.0.0/16'],
    type     => 'hash:net',
  }


# Allow all from FSU campus networks including RCC

  firewalld_rich_rule { 'FSU allow all':
    ensure  => present,
    zone    => 'rcczone',
    source  => { 'ipset' => 'fsu_networks' },
    action  => 'accept',
  }

}
#
