# VLAN resources for leaf switches
class cisco_datacentre::evpn::vlans (
  String $vxlan_vrf,
  Integer $vxlan_vni_prefix,
  Hash $vlans,
  Array $dhcp_servers,
  String $ospf_area_id,
  Boolean $hsrp_primary  = true,
) {

  if $::facts['function'] == 'leaf' {

    cisco_dhcp_relay_global { 'default' :
      ipv4_relay                  => true,
      ipv4_information_option     => true,
      ipv4_information_option_vpn => true,
      ipv4_sub_option_cisco       => true
    }

    $vlans.each |Integer $vlan_id, Hash $vlan_hash| {
      $vlan_keys = $vlan_hash.keys
      $vlan_vni = create_vni($vxlan_vni_prefix,$vlan_id)

      if 'dhcp_enabled' in $vlan_keys {
        if 'multicast_group' in $vlan_keys {
          cisco_datacentre::evpn::overlayvlan { "${vlan_id}" :
            vlan_id          => $vlan_id,
            vlan_name        => $vlan_hash['name'],
            vlan_ip          => $vlan_hash['ip'],
            vlan_mask        => $vlan_hash['mask'],
            vlan_mcast_group => $vlan_hash['multicast_group'],
            vlan_vni         => $vlan_vni,
            vxlan_vrf        => $vxlan_vrf,
            dhcp_servers     => $dhcp_servers,
          }
        }
        else {
          cisco_datacentre::evpn::underlayvlan { "${vlan_id}" :
            vlan_id      => $vlan_id,
            vlan_name    => $vlan_hash['name'],
            vlan_ip      => $vlan_hash['ip'],
            vlan_mask    => $vlan_hash['mask'],
            vlan_vip     => $vlan_hash['vip'],
            ospf_area_id => $ospf_area_id,
            hsrp_primary => $hsrp_primary,
            dhcp_servers => $dhcp_servers,
          }
        }
      }
      else {
        if 'multicast_group' in $vlan_keys {
          cisco_datacentre::evpn::overlayvlan { "${vlan_id}" :
            vlan_id          => $vlan_id,
            vlan_name        => $vlan_hash['name'],
            vlan_ip          => $vlan_hash['ip'],
            vlan_mask        => $vlan_hash['mask'],
            vlan_mcast_group => $vlan_hash['multicast_group'],
            vlan_vni         => $vlan_vni,
            vxlan_vrf        => $vxlan_vrf,
          }
        }
        else {
          cisco_datacentre::evpn::underlayvlan { "${vlan_id}" :
            vlan_id      => $vlan_id,
            vlan_name    => $vlan_hash['name'],
            vlan_ip      => $vlan_hash['ip'],
            vlan_mask    => $vlan_hash['mask'],
            vlan_vip     => $vlan_hash['vip'],
            ospf_area_id => $ospf_area_id,
            hsrp_primary => $hsrp_primary,
          }
        }
      }
    }
  }
  else {
    # borderleaf processing below; no SVI created
    $vlans.each |Integer $vlan_id, Hash $vlan_hash| {
      $vlan_vni = create_vni($vxlan_vni_prefix,$vlan_id)
      cisco_datacentre::evpn::layer2vlan { "${vlan_id}" :
        vlan_id   => $vlan_id,
        vlan_name => $vlan_hash['name'],
        vlan_vni  => $vlan_vni,
      }
    }
  }
}
