class cisco_datacentre::evpn::border_interfaces (
  Hash $core_interfaces,
  String $ospf_area,
  String $vxlan_vrf,
  String $ospf_process_name = 'UNDERLAY',
  Integer $default_mtu      = 9216,
  String $ospf_md5_password = '0$PFP@ssw0rd',
) {

  $core_interfaces.each | String $interface_name, Hash $interface_hash | {
    $interface_keys = $interface_hash.keys
    $description = $interface_hash['description']

    if 'mtu' in $interface_keys {
      $interface_mtu = $interface_hash['mtu']
    }
    else {
      $interface_mtu = $default_mtu
    }

    if 'vlan_id' in $interface_keys {
      if 'underlay' in $interface_keys {
        cisco_interface { $interface_name :
          ensure               => present,
          description          => $description,
          mtu                  => $interface_mtu,
          encapsulation_dot1q  => $interface_hash['vlan_id'],
          ipv4_address         => $interface_hash['ipaddress'],
          ipv4_netmask_length  => $interface_hash['mask'],
          ipv4_redirects       => false,
          ipv4_pim_sparse_mode => true,
          pim_bfd              => true,
          shutdown             => false,
        }
        cisco_interface_ospf { "${interface_name} ${ospf_process_name}" :
          ensure                         => present,
          area                           => $ospf_area,
          bfd                            => true,
          network_type                   => 'p2p',
          hello_interval                 => 3,
          message_digest                 => true,
          message_digest_key_id          => 1,
          message_digest_algorithm_type  => 'md5',
          message_digest_encryption_type => '3des',
          message_digest_password        => $ospf_md5_password,
          require                        => Cisco_ospf[$ospf_process_name],
        }
      }
      else {
        cisco_interface { $interface_name :
          ensure              => present,
          description         => $description,
          mtu                 => $interface_mtu,
          encapsulation_dot1q => $interface_hash['vlan_id'],
          vrf                 => $vxlan_vrf,
          ipv4_address        => $interface_hash['ipaddress'],
          ipv4_netmask_length => $interface_hash['mask'],
          ipv4_redirects      => false,
          shutdown            => false,
        }
      }
    }
    else {
      cisco_interface { $interface_name :
        ensure          => present,
        description     => $description,
        switchport_mode => 'disabled',
        mtu             => $interface_mtu,
      }
    }
  }
}
