# Resource types for Cisco VPC pair
class cisco_datacentre::vpc (
    String $peer_keepalive_src,
    String $peer_keepalive_dest,
    Boolean $primary,
    Optional[Integer[1,1000]] $domain,
    String $peerlink_po_id     = '100',
    Array $peerlink_interfaces = [ 'Ethernet1/53', 'Ethernet1/54'],
    String $peer_keepalive_vrf = 'management',
) {
  if $primary {
    cisco_vpc_domain { "${domain}" :
      ensure                       => present,
      role_priority                => 2000,
      system_priority              => 2000,
      peer_keepalive_dest          => $peer_keepalive_dest,
      peer_keepalive_src           => $peer_keepalive_src,
      peer_keepalive_vrf           => $peer_keepalive_vrf,
      delay_restore                => 240,
      delay_restore_interface_vlan => 240,
      peer_gateway                 => true,
      auto_recovery                => true,
    }
  } else {
    cisco_vpc_domain { "${domain}" :
      ensure                       => present,
      system_priority              => 2000,
      peer_keepalive_dest          => $peer_keepalive_dest,
      peer_keepalive_src           => $peer_keepalive_src,
      peer_keepalive_vrf           => $peer_keepalive_vrf,
      delay_restore                => 240,
      delay_restore_interface_vlan => 240,
      peer_gateway                 => true,
      auto_recovery                => true,
    }
  }
  cisco_interface { "port-channel${peerlink_po_id}" : # VPC Peerlink interface
    ensure                  => present,
    description             => 'vPC Peerlink',
    switchport_mode         => 'trunk',
    vpc_peer_link           => true,
    stp_port_type           => 'network',
    storm_control_broadcast => '90.00',
    storm_control_multicast => '90.00',
    shutdown                => false,
    require                 => Cisco_vpc_domain["${domain}"],
  }
  $peerlink_interfaces.each |String $interface| {
    cisco_interface { $interface :
      ensure                  => present,
      description             => "vPC Peerlink Po${peerlink_po_id}",
      switchport_mode         => 'trunk',
      stp_port_type           => 'network',
      storm_control_broadcast => '90.00',
      storm_control_multicast => '90.00',
      shutdown                => false,
    }
    cisco_interface_channel_group { $interface :
      ensure             => present,
      interface          => $interface,
      channel_group      => $peerlink_po_id,
      channel_group_mode => 'active',
      require            => Cisco_interface["port-channel${peerlink_po_id}"],
    }
  }
}
