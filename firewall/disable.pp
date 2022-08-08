# DISABLES firewalld entirely.  You might use this after
# removing a host from firewalld configuration, or for a clean
# start during testing, or something like that.

class rcc_firewalld::disable {
  class { '::firewalld':
    service_ensure => 'stopped',
    service_enable => false,
  }
#  firewalld_zone { 'rcczone':
#    ensure           => absent,
#    target           => '%%REJECT%%',
#    purge_rich_rules => true,
#    purge_services   => true,
#    purge_ports      => true,
#  }

}
