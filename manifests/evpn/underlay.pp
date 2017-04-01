# OSPF & PIM underlay routing resources.
# Same for all switches (leaf & spines)
class cisco_datacentre::evpn::underlay (
  String $loopback0_ip,
  String $ospf_area,
  Hash $ptp_interfaces,
  String $multicast_group_range,
  String $pim_anycast_rp,
  Hash $spine_bgp_peers,
  String $enterprise_pim_rp   = '',
  String $vlan2_ip            = '',
  String $vlan2_description   = '',
  Integer $vlan2_mtu          = 9216,
  String $ospf_process_name   = 'UNDERLAY',
  String $ospf_vrf            = 'default',
  String $ospf_md5_password   = '0$PFP@ssw0rd',
  String $all_multicast_range = '224.0.0.0/4',
) {

  cisco_interface { 'lo0-routerid' :
    ensure               => present,
    interface            => 'loopback0',
    shutdown             => false,
    description          => 'Underlay,Router ID',
    ipv4_address         => $loopback0_ip,
    ipv4_netmask_length  => 32,
    ipv4_pim_sparse_mode => true,
  }

  cisco_ospf { $ospf_process_name :
    ensure  => present,
  }

  cisco_ospf_vrf { "${ospf_process_name} ${ospf_vrf}" :
    ensure        => present,
    router_id     => $loopback0_ip,
    bfd           => true,
    log_adjacency => 'log',
    require       => Cisco_ospf[$ospf_process_name],
  }

  cisco_ospf_area { "${ospf_process_name} ${ospf_vrf} ${ospf_area}" :
    ensure         => present,
    authentication => 'md5',
    nssa           => true,
    require        => Cisco_ospf_vrf["${ospf_process_name} ${ospf_vrf}"],
  }

  cisco_interface_ospf { "loopback0 ${ospf_process_name}" :
    ensure    => present,
    interface => 'loopback0',
    ospf      => $ospf_process_name,
    area      => $ospf_area,
    require   => Cisco_ospf_vrf["${ospf_process_name} ${ospf_vrf}"],
  }

  $ptp_interfaces.each |String $interface_name, Hash $interface_hash| {
    $interface_keys = $interface_hash.keys
    if 'mtu' in $interface_keys {
      $interface_mtu = $interface_hash[mtu]
    }
    else {
      $interface_mtu = 9216
    }
    cisco_interface { $interface_name :
      ensure              => present,
      switchport_mode     => 'disabled',
      interface           => $interface_name,
      shutdown            => false,
      description         => $interface_hash['description'],
      mtu                 => $interface_mtu,
      ipv4_address        => $interface_hash['ipaddress'],
      ipv4_netmask_length => 31,
      ipv4_redirects      => false,
    }
    cisco_interface_ospf { "${interface_name} ${ospf_process_name}" :
      ensure                         => present,
      interface                      => $interface_name,
      ospf                           => $ospf_process_name,
      area                           => $ospf_area,
      bfd                            => true,
      hello_interval                 => 3,
      network_type                   => 'p2p',
      message_digest                 => true,
      message_digest_key_id          => 1,
      message_digest_algorithm_type  => 'md5',
      message_digest_encryption_type => '3des',
      message_digest_password        => $ospf_md5_password,
      require                        => Cisco_interface[$interface_name],
    }
  }
  # Route map req'd for PIM underlay
  cisco_route_map { "rm_vxlan_multicast_bum_groups 10 permit" :
    ensure                          => present,
    match_ipv4_multicast_enable     => true,
    match_ipv4_multicast_group_addr => $multicast_group_range,
  }
  cisco_command_config { 'vxlan_pim_rp' :
    command         => "ip pim rp-address ${pim_anycast_rp} route-map rm_vxlan_multicast_bum_groups",
  }
  # Misc PIM
  cisco_command_config { 'pim-misc' :
    command         => "ip pim ssm range 232.0.0.0/8\nip pim pre-build-spt",
  }
  if $::function == 'leaf' {
    if $enterprise_pim_rp == '' {
      fail('cisco_datacentre::evpn::underlay - Hiera lookup failed for enterprise_pim_rp')
    }
    cisco_vlan { '2' :
      ensure    => present,
      vlan_name => 'PTP,UNDERLAY,PEER-GW',
      state     => 'active',
      shutdown  => false,
    }
    cisco_interface { 'Vlan2' : # OSPF underlay SVI
      ensure              => present,
      interface           => 'Vlan2',
      shutdown            => false,
      description         => $vlan2_description,
      mtu                 => $vlan2_mtu,
      ipv4_address        => $vlan2_ip,
      ipv4_netmask_length => 31,
      ipv4_redirects      => false,
      bfd_echo            => false,
      require             => Cisco_vlan['2'],
    }
    cisco_interface_ospf { "Vlan2 ${ospf_process_name}" :
      ensure                         => present,
      interface                      => 'Vlan2',
      ospf                           => $ospf_process_name,
      area                           => $ospf_area,
      bfd                            => true,
      message_digest                 => true,
      message_digest_key_id          => 1,
      message_digest_algorithm_type  => 'md5',
      message_digest_encryption_type => '3des',
      message_digest_password        => $ospf_md5_password,
    }

    cisco_route_map { "rm_multicast_enterprise 10 permit" :
      ensure                          => present,
      match_ipv4_multicast_enable     => true,
      match_ipv4_multicast_group_addr => $all_multicast_range,
    }
    # PIM RP's
    cisco_command_config { 'leaf-pim-rp' :
      command => "ip pim rp-address ${enterprise_pim_rp} route-map rm_multicast_enterprise\nip pim rp-address ${loopback0_ip} route-map rm_multicast_local_clusters",
    }
  }
  if $::function == 'spine' {
    $spine_bgp_peers.each |String $bgp_peer_ip, String $bgp_peer_name| {
      cisco_command_config { "anycast-rp-${bgp_peer_name}" :
        command => "ip pim anycast-rp ${pim_anycast_rp} ${bgp_peer_ip}"
      }
    }
  }
}
