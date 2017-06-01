define cisco_datacentre::evpn::underlayvlan (
  Integer $vlan_id,
  String $vlan_name,
  String $vlan_ip,
  Integer $vlan_mask,
  String $vlan_vip,
  String $ospf_area_id,
  Boolean $hsrp_primary     = true,
  Integer $hsrp_group_id    = 1,
  String $ospf_process_name = 'UNDERLAY',
  Variant[Boolean,Array] $dhcp_servers = false,
) {

  if $hsrp_primary {
    $hsrp_priority = 200
    # $pim_dr_priority = 100 <--- This property hasn't been implemented yet
  }
  else {
    $hsrp_priority = 100
  }

  cisco_vlan { "${vlan_id}" :
    ensure    => present,
    vlan_name => $vlan_name,
    state     => 'active',
    shutdown  => false,
  }
  if $dhcp_servers {
    cisco_interface { "Vlan${vlan_id}" :
      ensure               => present,
      interface            => "Vlan${vlan_id}",
      description          => $vlan_name,
      shutdown             => false,
      ipv4_address         => $vlan_ip,
      ipv4_netmask_length  => $vlan_mask,
      ipv4_redirects       => false,
      ipv4_arp_timeout     => 300,
      ipv4_pim_sparse_mode => true,
      pim_bfd              => true,
      ipv4_dhcp_relay_addr => $dhcp_servers,
    }
  }
  else {
    cisco_interface { "Vlan${vlan_id}" :
      ensure               => present,
      interface            => "Vlan${vlan_id}",
      description          => $vlan_name,
      shutdown             => false,
      ipv4_address         => $vlan_ip,
      ipv4_netmask_length  => $vlan_mask,
      ipv4_redirects       => false,
      ipv4_arp_timeout     => 300,
      ipv4_pim_sparse_mode => true,
      pim_bfd              => true,
    }
  }

  cisco_interface_ospf { "Vlan${vlan_id} ${ospf_process_name}" :
    ensure            => present,
    interface         => "Vlan${vlan_id}",
    bfd               => true,
    ospf              => $ospf_process_name,
    area              => $ospf_area_id,
    cost              => 90,
    passive_interface => true,
  }
  cisco_interface_hsrp_group { "vlan${vlan_id} ${hsrp_group_id} ipv4" :
    ensure      => present,
    ipv4_enable => true,
    ipv4_vip    => $vlan_vip,
    priority    => $hsrp_priority,
    preempt     => true,
  }
}
