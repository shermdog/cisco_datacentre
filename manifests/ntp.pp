class cisco_datacentre::ntp (
  Array $ntpservers,
  String $ntp_acl_name = 'NTP_ACL',
) {

  cisco_acl { "ipv4 ${ntp_acl_name}" :
    ensure => present,
  }

  $ntpservers.each |Integer $index,String $ntp_ip| {
    validate_ip_address($ntp_ip)

    $acl_seqnum = ($index + 1) * 10

    cisco_ace { "ipv4 ${ntp_acl_name} ${acl_seqnum}" :
      ensure   => present,
      action   => 'permit',
      proto    => 'ip',
      src_addr => "${ntp_ip}/32",
      dst_addr => 'any',
      require  => Cisco_acl["ipv4 ${ntp_acl_name}"],
    }

    cisco_command_config { "ntp-server-${index}" :
      command => "ntp server ${ntp_ip} use-vrf management"
    }
  }

  cisco_command_config  { 'ntp-server-acl' :
    command => "ntp access-group peer ${ntp_acl_name}"
  }

}
