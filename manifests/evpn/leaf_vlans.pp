# Leaf pairs will do almost all gateway processing for EVPN Layer3 vlans
# No DHCP or gateway on the border leaf's
class cisco_datacentre::evpn::leaf_vlans (
  String $vxlan_vrf,
  Integer $vxlan_vni_prefix,
  Hash $vlans,
  Array $dev_dhcp_servers,
  Array $sai_dhcp_servers,
  Array $prod_dhcp_servers,
  String $ospf_area_id,
  Boolean $hsrp_primary  = true,
) {

  cisco_dhcp_relay_global { 'default' :
    ipv4_relay                  => true,
    ipv4_information_option     => true,
    ipv4_information_option_vpn => true,
    ipv4_sub_option_cisco       => true
  }

  $vlans.each |Integer $vlan_id, Hash $vlan_hash| {
    $vlan_vni = create_vni($vxlan_vni_prefix,$vlan_id)

    if has_key($vlans[$vlan_id], 'multicast_group') {
      rbc_cisco_datacentre::evpn::overlayvlan { "${vlan_id}" :
        vlan_id          => $vlan_id,
        vlan_name        => $vlan_hash['name'],
        vlan_ip          => $vlan_hash['ip'],
        vlan_mask        => $vlan_hash['mask'],
        vlan_mcast_group => $vlan_hash['multicast_group'],
        vlan_vni         => $vlan_vni,
        vxlan_vrf        => $vxlan_vrf,
      }
    }
    elsif has_key($vlans[$vlan_id], 'vip') {
      rbc_cisco_datacentre::evpn::underlayvlan { "${vlan_id}" :
        vlan_id      => $vlan_id,
        vlan_name    => $vlan_hash['name'],
        vlan_ip      => $vlan_hash['ip'],
        vlan_mask    => $vlan_hash['mask'],
        vlan_vip     => $vlan_hash['vip'],
        ospf_area_id => $ospf_area_id,
        hsrp_primary => $hsrp_primary,
      }
    }
    elsif type($vlans[$vlan_id], generalized) == String {
      rbc_cisco_datacentre::evpn::layer2vlan { "${vlan_id}" :
        vlan_id   => $vlan_id,
        vlan_name => $vlans[$vlan_id],
      }
    }
    else {
      fail("ERROR: VLAN${vlan_id} data is incorrect. Must contain either \
        overlay or underlay keys (multicast_group, vip) or be key-value \
        pairs of vlan_id: vlan_name")
    }
  }
}
