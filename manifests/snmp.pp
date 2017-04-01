# Generic SNMP class; applies syslocation, add's community strings w/ associated ACL's
class cisco_datacentre::snmp (
  Hash $read_only,
  Hash $read_write,
  String $syslocation_string = '',
  String $syscontact_string  = '',
) {

  $read_only.each |String $ro_community_string, Hash $ro_acl_hash| {
    $acl_names = $ro_acl_hash.keys

    $acl_names.each |String $acl_name| {
      # $acl_resource_name = join(['ipv4', $acl_name], ' ')

      cisco_acl { "ipv4 ${acl_name}" :
        ensure => present,
      }

      $acl_entries = $read_only[$ro_community_string][$acl_name]

      $acl_entries.each |Integer $index, String $acl_entry| {
        $ace_seqnum = ($index + 1) * 10
        # $ace_resource_name = join(['ipv4', $acl_name, $ace_seqnum], ' ')

        cisco_ace { "ipv4 ${acl_name} ${ace_seqnum}" :
          ensure   => present,
          action   => 'permit',
          proto    => 'ip',
          src_addr => $acl_entry,
          dst_addr => 'any',
          require  => Cisco_acl["ipv4 ${acl_name}"],
        }

      }

      cisco_snmp_community { $ro_community_string :
        ensure    => present,
        community => $ro_community_string,
        group     => 'network-operator',
        acl       => $acl_name,
        require   => Cisco_acl["ipv4 ${acl_name}"],
      }

    }

  }

  $read_write.each |String $rw_community_string, Hash $rw_acl_hash| {
    $acl_names = $rw_acl_hash.keys

    $acl_names.each |String $acl_name| {
      # $acl_resource_name = join(['ipv4', $acl_name], ' ')

      cisco_acl { "ipv4 ${acl_name}" :
        ensure => present,
      }

      $acl_entries = $read_write[$rw_community_string][$acl_name]

      $acl_entries.each |Integer $index, String $acl_entry| {
        $ace_seqnum = ($index + 1) * 10
        # $ace_resource_name = join(['ipv4', $acl_name, $ace_seqnum], ' ')

        cisco_ace { "ipv4 ${acl_name} ${ace_seqnum}" :
          ensure   => present,
          action   => 'permit',
          proto    => 'ip',
          src_addr => $acl_entry,
          dst_addr => 'any',
          require  => Cisco_acl["ipv4 ${acl_name}"],
        }

      }

      cisco_snmp_community { $rw_community_string :
        ensure    => present,
        community => $rw_community_string,
        group     => 'network-admin',
        acl       => $acl_name,
        require   => Cisco_acl["ipv4 ${acl_name}"],
      }

    }

  }

  cisco_snmp_server { 'default':
    location => $syslocation_string,
    contact  => $syscontact_string,
  }
}
