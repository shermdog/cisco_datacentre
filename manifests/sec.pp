# Apply basic global commands for security
# If syslog interface is different from "mgmt0", pass in as parameter
class cisco_datacentre::sec (
  String $syslog_sourceint = 'mgmt0',
) {

  cisco_command_config { 'system-vlan-long-name' :
    command => 'system vlan long-name',
  }

  cisco_command_config { 'logging-source-interface' :
    command => "logging source-interface ${syslog_sourceint}",
  }

  cisco_command_config { 'logging-logfile-messages' :
    command => 'logging logfile messages 7',
  }

  cisco_command_config { 'logging-timestamp-milliseconds' :
    command => 'logging timestamp milliseconds',
  }

  cisco_command_config { 'no-logging-console' :
    command => 'no logging console',
  }

  cisco_command_config { 'no-logging-monitor' :
    command => 'no logging monitor',
  }

  cisco_command_config { 'logging-event-trunk-status' :
    command => 'logging event trunk-status enable',
  }

  cisco_command_config { 'logging-message' :
    command => 'logging message interface type ethernet description',
  }

  cisco_command_config { 'no-ip-source-route' :
    command => 'no ip source-route',
  }

  cisco_command_config { 'no-domain-lookup' :
    command => 'no ip domain-lookup',
  }

  cisco_command_config { 'ssh-login-attempts' :
    command => 'ssh login-attempts 2',
  }

  cisco_command_config { 'clock-format-show-timezone' :
    command => 'clock format show-timezone syslog',
  }

  cisco_command_config { 'no-clock-summer-time' :
    command => 'no clock summer-time',
  }

  cisco_command_config { 'line-console' :
    command => "line console\n  exec-timeout 15\nline vty\n  session-limit 5\n  exec-timeout 15",
  }

  unless $::timezone == 'UTC' {
      cisco_command_config { 'clock-timezone' :
          command => 'clock timezone UTC 0 0',
      }
  }
}
