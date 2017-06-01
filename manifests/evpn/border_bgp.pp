# Border BGP routing for VXLAN EVPN networks
class cisco_datacentre::evpn::border_bgp (
  String $loopback0_ip,
  String $bgp_asn,
  String $vxlan_vrf,
  Hash $external_bgp_neighbors,
  Array $advertised_networks,
  String $bgp_password         = '3GP@ssw0rd',
) {

  cisco_bgp { "${bgp_asn} ${vxlan_vrf}" :
    ensure    => present,
    router_id => $loopback0_ip,
  }

  $advertised_networks.each | Integer $index, String $network | {
    $pl_index = ($index + 1) * 10
    cisco_command_config { "pl_allowed_networks_${pl_index}" :
      command => "ip prefix-list pl_allowed_networks seq ${pl_index} permit ${network}",
    }
  }

  cisco_route_map { "rm_pod_as${bgp_asn}_out 1000 permit" :
    ensure                      => present,
    match_ipv4_addr_prefix_list => 'pl_allowed_networks',
    set_community_asn           => "${bgp_asn}:100",
  }

  $external_bgp_neighbors.each |String $bgp_peer_ip, Hash $bgp_peer_hash| {

    cisco_bgp_neighbor { "${bgp_asn} ${vxlan_vrf} ${bgp_peer_ip}" :
      ensure        => present,
      description   => $bgp_peer_hash['description'],
      bfd           => true,
      remote_as     => $bgp_peer_hash['asn'],
      password      => $bgp_password,
      password_type => '3des',
    }
    cisco_bgp_neighbor_af { "${bgp_asn} ${vxlan_vrf} ${bgp_peer_ip} ipv4 unicast" :
      ensure                  => present,
      send_community          => 'standard',
      soft_reconfiguration_in => 'always',
      route_map_out           => "rm_pod_as${bgp_asn}_out",
      require                 => Cisco_route_map["rm_pod_as${bgp_asn}_out 1000 permit"],
    }
  }
  $cisco_formatted_networks = evpn_bgp_network_array($advertised_networks)
  cisco_bgp_af { 'border_network_advertisements' :
    ensure               => present,
    asn                  => $bgp_asn,
    vrf                  => $vxlan_vrf,
    afi                  => 'ipv4',
    safi                 => 'unicast',
    advertise_l2vpn_evpn => true,
    maximum_paths        => 4,
    maximum_paths_ibgp   => 4,
    networks             => $cisco_formatted_networks,
  }
}
