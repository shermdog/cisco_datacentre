# Base class for setting up the Guestshell environment
class cisco_datacentre::base (
  String $gempath                        = '/root',
  Variant[String,Boolean] $install_repo  = false,
  Variant[String,Boolean] $install_proxy = false,
  String $vrf                            = 'management',
) {
  # Root user password not initially set, which upsets PAM & screws up cron
  user { 'root' :
    ensure   => present,
    password => 'Password123!',
  }

  if $install_repo and $install_proxy {
    class { 'ciscopuppet::install' :
      repo  => $install_repo,
      proxy => $install_proxy,
    }
  }
  elsif $install_repo {
    class { 'ciscopuppet::install' :
      repo  => $install_repo,
    }
  }
  elsif $install_proxy {
    class { 'ciscopuppet::install' :
      proxy => $install_proxy,
    }
  }
  else {
    include ciscopuppet::install
  }

  file_line { 'add_vrf_to_puppet.service' :
      path   => '/usr/lib/systemd/system/puppet.service',
      line   => "ExecStart=/bin/nsenter --net=/var/run/netns/${vrf} -- /opt/puppetlabs/puppet/bin/puppet agent \$PUPPET_EXTRA_OPTS --no-daemonize",
      match  => '^ExecStart',
      notify => Exec['trigger_systemd_daemon-reload'],
  }

  service { 'puppet' :
      ensure  => running,
      enable  => true,
      require => File_line['add_vrf_to_puppet.service'],
  }

  # Required for agent to use management vrf
  file_line { 'add_vrf_to_mcollective.service' :
      path   => '/usr/lib/systemd/system/mcollective.service',
      line   => "ExecStart=/bin/nsenter --net=/var/run/netns/${vrf} -- /opt/puppetlabs/puppet/bin/mcollectived --config=/etc/puppetlabs/mcollective/server.cfg --pidfile=/var/run/puppetlabs/mcollective.pid --daemonize",
      match  => '^ExecStart',
      notify => [Service['mcollective'],Exec['trigger_systemd_daemon-reload']],
  }

  file_line { 'add_vrf_to_pxp-agent.service' :
      path   => '/usr/lib/systemd/system/pxp-agent.service',
      line   => "ExecStart=/bin/nsenter --net=/var/run/netns/${vrf} -- /opt/puppetlabs/puppet/bin/pxp-agent \$PXP_AGENT_OPTIONS --foreground",
      match  => '^ExecStart',
      notify => Exec['trigger_systemd_daemon-reload'],
  }
  file { 'pxp-agent_varlog_dir' :
      ensure  => directory,
      path    => '/var/log/puppetlabs/pxp-agent',
      require => File_line['add_vrf_to_pxp-agent.service'],
      notify  => Service['pxp-agent'],
  }
  exec { 'trigger_systemd_daemon-reload' :
    command     => '/bin/systemctl daemon-reload',
    refreshonly => true,
  }

}
