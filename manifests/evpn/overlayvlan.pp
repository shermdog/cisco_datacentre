define cisco_datacentre::evpn::overlayvlan (
  Integer $vlan_id,
  String $vlan_name,
  String $vlan_ip,
  Integer $vlan_mask,
  Integer $vlan_vni,
  String $vlan_mcast_group,
  String $vxlan_vrf,
  Variant[Boolean,Array] $dhcp_servers = false,
) {
  cisco_vlan { "${vlan_id}" :
    ensure     => present,
    vlan_name  => $vlan_name,
    mapped_vni => $vlan_vni,
    state      => 'active',
    shutdown   => false,
  }
  cisco_vxlan_vtep_vni { "nve1 ${vlan_vni}" :
    ensure          => present,
    assoc_vrf       => false,
    multicast_group => $vlan_mcast_group,
    suppress_arp    => true,
  }

  cisco_evpn_vni { "${vlan_vni}" :
    ensure              => present,
    route_distinguisher => 'auto',
    route_target_import => 'auto',
    route_target_export => 'auto',
  }

  if $dhcp_servers {
    cisco_interface { "Vlan${vlan_id}" :
      ensure                            => present,
      interface                         => "Vlan${vlan_id}",
      description                       => $vlan_name,
      shutdown                          => false,
      mtu                               => 9216,
      vrf                               => $vxlan_vrf,
      ipv4_address                      => $vlan_ip,
      ipv4_netmask_length               => $vlan_mask,
      ipv4_redirects                    => false,
      ipv4_arp_timeout                  => 300,
      ipv4_dhcp_relay_addr              => $dhcp_servers,
      fabric_forwarding_anycast_gateway => true,
      require                           => Cisco_dhcp_relay_global['default'],
    }
  }
  else {
    cisco_interface { "Vlan${vlan_id}" :
      ensure                            => present,
      interface                         => "Vlan${vlan_id}",
      description                       => $vlan_name,
      shutdown                          => false,
      mtu                               => 9216,
      vrf                               => $vxlan_vrf,
      ipv4_address                      => $vlan_ip,
      ipv4_netmask_length               => $vlan_mask,
      ipv4_redirects                    => false,
      ipv4_arp_timeout                  => 300,
      fabric_forwarding_anycast_gateway => true,
    }
  }

}
