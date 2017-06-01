define cisco_datacentre::evpn::layer2vlan (
  Integer $vlan_id,
  String $vlan_name,
) {
  cisco_vlan { "${vlan_id}" :
    ensure    => present,
    vlan_name => $vlan_name,
    state     => 'active',
    shutdown  => false,
  }
}
