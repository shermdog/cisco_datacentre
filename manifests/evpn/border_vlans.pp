# Future state class for border leafs with no Layer3 or DHCP features
# border leafs will be strictly used for external routing & extending
# layer 2 beyond fabrics
class cisco_datacentre::evpn::border_vlans (
  Hash $vlans,
  Integer $vxlan_vni_prefix,
) {

  $vlans.each |Integer $vlan_id, Hash $vlan_hash| {
    $vlan_keys = $vlan_hash.keys
    $vlan_vni = create_vni($vxlan_vni_prefix,$vlan_id)

    if 'multicast_group' in $vlan_keys {
      rbc_cisco_datacentre::evpn::layer2vxlan { "${vlan_id}" :
        vlan_id          => $vlan_id,
        vlan_name        => $vlan_hash['name'],
        vlan_mcast_group => $vlan_hash['multicast_group'],
        vlan_vni         => $vlan_vni,
      }
    }
    elsif type($vlans[$vlan_id], generalized) == String {
      rbc_cisco_datacentre::evpn::layer2vlan { "${vlan_id}" :
        vlan_id   => $vlan_id,
        vlan_name => $vlans[$vlan_id],
      }
    }
    else {
      notice("No VLAN configuration for ${vlan_id} to be applied for ${::fqdn}")
    }
  }
}
