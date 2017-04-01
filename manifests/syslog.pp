class cisco_datacentre::syslog (
  Array $syslog_servers,
  String $syslog_vrf     = 'management',
) {
  $syslog_servers.each | String $server_ip | {
    cisco_command_config { "syslog_${server_ip}" :
      command => "logging server ${server_ip} 6 use-vrf ${syslog_vrf}",
    }
  }
}
