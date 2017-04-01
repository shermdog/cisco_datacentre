define cisco_datacentre::evpn::layer2vlan (
  Integer $vlan_id,
  String $vlan_name,
  Integer $vlan_vni,
) {
  cisco_vlan { "${vlan_id}" :
    ensure     => present,
    vlan_name  => $vlan_name,
    mapped_vni => $vlan_vni,
    state      => 'active',
    shutdown   => false,
  }
}
