# Global resources required for all leaf switches
class cisco_datacentre::evpn::leafglobal (
  String $anycast_mac           = '0200.fab0.0001',
  Integer $bfd_tx_internal      = 150,
  Integer $bfd_minrx_internal   = 150,
  Integer $bfd_multiplier       = 3,
  Integer $default_stp_priority = 24576,
) {

  cisco_bfd_global { 'default' :
    ensure        => present,
    ipv4_interval => [ $bfd_tx_internal, $bfd_minrx_internal, $bfd_multiplier ],
    startup_timer => 0,
  }

  cisco_stp_global { 'default' :
    mode          => 'rapid-pvst',
    bpduguard     => true,
    pathcost      => 'long',
    vlan_priority => [ [ '1-3967', "${default_stp_priority}" ] ],
  }

  cisco_overlay_global { 'default' :
    anycast_gateway_mac                   => $anycast_mac,
    dup_host_ip_addr_detection_host_moves => 5,
    dup_host_ip_addr_detection_timeout    => 180,
  }
}
