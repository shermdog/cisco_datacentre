# EVPN resources for spine underlay
class cisco_datacentre::evpn::spineunderlay (
  String $loopback0_ip,
  String $ospf_area,
  Hash $ptp_interfaces,
  String $multicast_group_range,
  String $pim_anycast_rp,
  Hash $spine_bgp_peers,
  String $ospf_process_name          = 'UNDERLAY',
  String $ospf_vrf                   = 'default',
  String $ospf_md5_password          = '0$PFP@ssw0rd',
  String $default_ssm_range          = '232.0.0.0/8',
  Integer $default_ptp_mtu           = 9216,
) {

  cisco_ospf { $ospf_process_name :
    ensure => present,
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

  cisco_interface { 'lo0-routerid' :
    ensure               => present,
    interface            => 'loopback0',
    shutdown             => false,
    description          => 'Underlay,Router ID',
    ipv4_address         => $loopback0_ip,
    ipv4_netmask_length  => 32,
    ipv4_pim_sparse_mode => true,
  }

  cisco_interface { 'loopback1' :
    ensure               => present,
    interface            => 'loopback1',
    shutdown             => false,
    description          => 'Anycast RP',
    ipv4_address         => $pim_anycast_rp,
    ipv4_netmask_length  => 32,
    ipv4_pim_sparse_mode => true,
  }

  cisco_interface_ospf { "loopback0 ${ospf_process_name}" :
    ensure    => present,
    interface => 'loopback0',
    ospf      => $ospf_process_name,
    area      => $ospf_area,
    require   => Cisco_ospf_vrf["${ospf_process_name} ${ospf_vrf}"],
  }

  cisco_interface_ospf { "loopback1 ${ospf_process_name}" :
    ensure    => present,
    interface => 'loopback1',
    ospf      => $ospf_process_name,
    area      => $ospf_area,
    require   => Cisco_ospf_vrf["${ospf_process_name} ${ospf_vrf}"],
  }

  $ptp_interfaces.each |String $interface_name, Hash $interface_hash| {
    if has_key($interface_hash, 'mtu') {
      $interface_mtu = $interface_hash['mtu']
    }
    else {
      $interface_mtu = $default_ptp_mtu
    }

    cisco_interface { $interface_name :
      ensure               => present,
      switchport_mode      => 'disabled',
      interface            => $interface_name,
      shutdown             => false,
      description          => $interface_hash['description'],
      mtu                  => $interface_mtu,
      ipv4_address         => $interface_hash['ipaddress'],
      ipv4_netmask_length  => 31,
      ipv4_redirects       => false,
      ipv4_pim_sparse_mode => true,
      pim_bfd              => true,
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

  cisco_pim { 'ipv4 default' :
    ensure    => present,
    bfd       => true,
    ssm_range => $default_ssm_range,
  }
  cisco_command_config { 'pim-misc' :
    command => "ip pim pre-build-spt",
  }

  cisco_route_map  { 'rm_vxlan_multicast_bum_groups 10 permit' :
      ensure                          => present,
      match_ipv4_multicast_enable     => true,
      match_ipv4_multicast_group_addr => $multicast_group_range,
  }
  # lint:ignore:140chars this command config is just simply long and req'd
  cisco_command_config { 'vxlan_pim_rp' :
    command => "ip pim rp-address ${pim_anycast_rp} route-map rm_vxlan_multicast_bum_groups",
  }
  # lint:endignore

  $spine_bgp_peers.each |String $bgp_peer_ip, String $bgp_peer_name| {
    cisco_command_config { "anycast-rp-${bgp_peer_name}" :
      command => "ip pim anycast-rp ${pim_anycast_rp} ${bgp_peer_ip}"
    }
  }

}
