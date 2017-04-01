# User-facing (server access) interfaces
class cisco_datacentre::userports (
  Hash $user_interfaces,
) {

  $user_int_keys = $user_interfaces.keys
  $user_int_keys.each |String $interface_name| {

    if type($user_interfaces[$interface_name], generalized) == String {
      cisco_interface { $interface_name:
        ensure      => present,
        interface   => $interface_name,
        description => $user_interfaces[$interface_name],
        shutdown    => true,
      }
    }
    else {
      $interface_hash = $user_interfaces[$interface_name]
      $interface_keys = $interface_hash.keys
      if 'access_vlan' in $interface_keys {
        $int_description = $interface_hash['description']
        $int_access_vlan = $interface_hash['access_vlan']
        cisco_interface { $interface_name:
          ensure          => present,
          interface       => $interface_name,
          shutdown        => false,
          description     => $int_description,
          switchport_mode => 'access',
          stp_bpduguard   => 'enable',
          access_vlan     => $int_access_vlan,
        }
      }
      elsif 'vpc_id' in $interface_keys {
        $int_description = $interface_hash['description']
        $int_allowed_vlans = $interface_hash['allowed_vlans']
        $int_vpc_id = $interface_hash['vpc_id']
        cisco_interface { $interface_name:
          ensure                        => present,
          interface                     => $interface_name,
          shutdown                      => false,
          description                   => $int_description,
          switchport_mode               => 'trunk',
          switchport_trunk_allowed_vlan => $int_allowed_vlans,
          stp_bpduguard                 => 'enable',
          stp_port_type                 => 'edge trunk',
        }
        cisco_interface { "port-channel${int_vpc_id}" :
          ensure                        => present,
          interface                     => "port-channel${int_vpc_id}",
          shutdown                      => false,
          description                   => $int_description,
          switchport_mode               => 'trunk',
          switchport_trunk_allowed_vlan => $int_allowed_vlans,
          stp_bpduguard                 => 'enable',
          stp_port_type                 => 'edge trunk',
          vpc_id                        => $int_vpc_id,
        }
        cisco_interface_channel_group { "${interface_name}-Po${int_vpc_id}" :
          ensure             => present,
          interface          => $interface_name,
          channel_group      => $int_vpc_id,
          require            => Cisco_interface["port-channel${int_vpc_id}"],
        }
      }
      elsif 'allowed_vlans' in $interface_keys {
        $int_description = $interface_hash['description']
        $int_allowed_vlans = $interface_hash['allowed_vlans']
        cisco_interface { $interface_name:
          ensure                        => present,
          interface                     => $interface_name,
          shutdown                      => false,
          description                   => $int_description,
          switchport_mode               => 'trunk',
          switchport_trunk_allowed_vlan => $int_allowed_vlans,
          stp_bpduguard                 => 'enable',
          stp_port_type                 => 'edge trunk',
        }
      }
      else {
        fail("cisco_datacentre::userports - Invalid Hiera data obtained \
        for ${interface_name}. Only key-value pairs or hashes are accepted.")
      }
    }
  }
}
