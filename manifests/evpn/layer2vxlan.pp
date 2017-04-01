define cisco_datacentre::evpn::layer2vxlan (
  Integer $vlan_id,
  String $vlan_name,
  Integer $vlan_vni,
  String $vlan_mcast_group,
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
}
