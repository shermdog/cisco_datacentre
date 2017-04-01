require 'spec_helper'
describe 'cisco_datacentre::base', :type => :class do
  let(:node) { 'nexus_switch.example.com'}
  describe 'when called on Cisco NXOS switches' do
    let(:facts) {{
       :osfamily => 'RedHat',
       :operatingsystem => 'nexus'
    }}

    it { is_expected.to contain_class('cisco_datacentre::base') }

    context 'with default values for all parameters' do
      it 'set the root user password' do
        is_expected.to contain_user('root').with({
          :ensure => 'present',
          :password => 'Password123!'
        })
      end
      it 'modify puppet systemd, ensure running' do
        is_expected.to contain_file_line('add_vrf_to_puppet.service').with({
          :path   => '/usr/lib/systemd/system/puppet.service',
          :line   => "ExecStart=/bin/nsenter --net=/var/run/netns/management -- /opt/puppetlabs/puppet/bin/puppet agent $PUPPET_EXTRA_OPTS --no-daemonize",
          :match  => '^ExecStart',
          }).that_notifies('Exec[trigger_systemd_daemon-reload]')
        is_expected.to contain_service('puppet').with({
          :ensure => 'running',
          :enable => true,
          }).that_requires('File_line[add_vrf_to_puppet.service]')
      end
      it 'modify mcollective systemd' do
        is_expected.to contain_file_line('add_vrf_to_mcollective.service').with({
          :path   => '/usr/lib/systemd/system/mcollective.service',
          :line   => "ExecStart=/bin/nsenter --net=/var/run/netns/management -- /opt/puppetlabs/puppet/bin/mcollectived --config=/etc/puppetlabs/mcollective/server.cfg --pidfile=/var/run/puppetlabs/mcollective.pid --daemonize",
          :match  => '^ExecStart'
          }).that_notifies(['Service[mcollective]','Exec[trigger_systemd_daemon-reload]'])
      end
      it 'modify pxp-agent systemd & ensure varlog exists' do
        is_expected.to contain_file_line('add_vrf_to_pxp-agent.service').with({
          :path   => '/usr/lib/systemd/system/pxp-agent.service',
          :line   => "ExecStart=/bin/nsenter --net=/var/run/netns/management -- /opt/puppetlabs/puppet/bin/pxp-agent $PXP_AGENT_OPTIONS --foreground",
          :match  => '^ExecStart',
          }).that_notifies('Exec[trigger_systemd_daemon-reload]')

        is_expected.to contain_file('pxp-agent_varlog_dir').with({
          :ensure  => 'directory',
          :path    => '/var/log/puppetlabs/pxp-agent',
          }).that_requires('File_line[add_vrf_to_pxp-agent.service]').that_notifies('Service[pxp-agent]')
      end
    end
  end
end
