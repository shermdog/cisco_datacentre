# Leaf EVPN overlay resources (NVE/BGP)
class cisco_datacentre::evpn::leafoverlay (
  String $bgp_asn,
  Integer $vxlan_vni_prefix,
  String $vxlan_vrf,
  Hash $spine_bgp_peers,
  String $loopback0_ip,
  String $bgp_password      = '3GP@ssw0rd',
  Integer $l3vni_vlan_id    = 10,
) {

  $l3vni_vni_id = create_vni($vxlan_vni_prefix, $l3vni_vlan_id)
  cisco_vlan { "${l3vni_vlan_id}":
    ensure     => present,
    mapped_vni => $l3vni_vni_id,
    vlan_name  => 'L3VNI',
    state      => 'active',
    shutdown   => false,
  }
  cisco_vrf { $vxlan_vrf:
    ensure              => present,
    route_distinguisher => 'auto',
  }
  cisco_interface { "Vlan${l3vni_vlan_id}" :
    ensure          => present,
    interface       => "Vlan${l3vni_vlan_id}",
    shutdown        => false,
    description     => 'L3VNI',
    mtu             => 9216,
    vrf             => $vxlan_vrf,
    ipv4_forwarding => true,
    require         => [ Cisco_vlan["${l3vni_vlan_id}"] , Cisco_vrf[$vxlan_vrf] ],
  }
  cisco_vrf_af { "${vxlan_vrf} ipv4 unicast" :
    ensure                      => present,
    route_target_both_auto_evpn => true,
    route_target_both_auto      => true,
  }
  cisco_vxlan_vtep { 'nve1' :
    ensure                          => present,
    description                     => 'NVE overlay interface',
    host_reachability               => 'evpn',
    shutdown                        => false,
    source_interface                => 'loopback1',
    source_interface_hold_down_time => 360,
  }
  # L3VNI
  cisco_vxlan_vtep_vni { "nve1 ${l3vni_vni_id}" :
    ensure    => present,
    assoc_vrf => true,
    require   => Cisco_vlan["${l3vni_vlan_id}"],
  }

  cisco_command_config { 'associate_l3vni_fix' :
    command => "vrf context ${vxlan_vrf}\n  vni ${l3vni_vni_id}",
  }

  cisco_bgp { "${bgp_asn} default" :
    ensure               => present,
    router_id            => $loopback0_ip,
    log_neighbor_changes => true,
  }

  $spine_bgp_peers.each |String $bgp_peer_ip, String $bgp_peer_name| {

    cisco_bgp_neighbor { "${bgp_asn} default ${bgp_peer_ip}" :
      ensure        => present,
      description   => $bgp_peer_name,
      bfd           => true,
      remote_as     => $bgp_asn,
      update_source => 'loopback0',
      password      => $bgp_password,
      password_type => '3des',
    }

    cisco_bgp_neighbor_af { "${bgp_asn} default ${bgp_peer_ip} l2vpn evpn" :
      ensure                  => present,
      send_community          => 'both',
      soft_reconfiguration_in => 'always',
    }
  }
}
