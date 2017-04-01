# Global resources required for all leaf switches
class cisco_datacentre::evpn::leafglobal (
  String $anycast_mac = '0200.fab1.0001',
) {

  cisco_bfd_global { 'default' :
    ensure        => present,
    ipv4_interval => [ 150, 150, 3 ],
    startup_timer => 0,
  }

  cisco_stp_global { 'default' :
    mode          => 'rapid-pvst',
    bpduguard     => true,
    pathcost      => 'long',
    vlan_priority => [ [ '1-3967', '24576' ] ],
  }

  cisco_overlay_global { 'default' :
    anycast_gateway_mac                   => $anycast_mac,
    dup_host_ip_addr_detection_host_moves => 5,
    dup_host_ip_addr_detection_timeout    => 180,
  }
}
