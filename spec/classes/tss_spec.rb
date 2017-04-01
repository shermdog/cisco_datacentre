require 'spec_helper'
describe 'cisco_datacentre::sec', :type => :class do
  let(:node) { 'nexus_switch.example.com'}
  describe 'when called with sane parameters on Cisco N9K switches' do
    let(:facts) {{
       :osfamily => 'RedHat',
       :operatingsystem => 'nexus',
       :timezone => 'UTC'
    }}
    let(:params) {{
       :syslog_sourceint => 'mgmt0'
    }}

    it { is_expected.to contain_class('cisco_datacentre::sec') }

    context 'call sec string' do
      let(:params) {{
         :syslog_sourceint => 'mgmt0'
      }}
      it 'enable sec_smnp commands' do
        is_expected.to contain_cisco_command_config('system-vlan-long-name').with({
          :command => "system vlan long-name"
        })
        is_expected.to contain_cisco_command_config('logging-source-interface').with({
          :command => "logging source-interface mgmt0"
        })
        is_expected.to contain_cisco_command_config('logging-logfile-messages').with({
          :command => "logging logfile messages 7"
        })
        is_expected.to contain_cisco_command_config('logging-timestamp-milliseconds').with({
          :command => "logging timestamp milliseconds"
        })
        is_expected.to contain_cisco_command_config('no-logging-console').with({
          :command => "no logging console"
        })
        is_expected.to contain_cisco_command_config('no-logging-monitor').with({
          :command => "no logging monitor"
        })
        is_expected.to contain_cisco_command_config('logging-event-trunk-status').with({
          :command => "logging event trunk-status enable"
        })
        is_expected.to contain_cisco_command_config('logging-message').with({
          :command => "logging message interface type ethernet description"
        })
        is_expected.to contain_cisco_command_config('no-ip-source-route').with({
          :command => "no ip source-route"
        })
        is_expected.to contain_cisco_command_config('no-domain-lookup').with({
          :command => "no ip domain-lookup"
        })
        is_expected.to contain_cisco_command_config('ssh-login-attempts').with({
          :command => "ssh login-attempts 2"
        })
        is_expected.to contain_cisco_command_config('clock-format-show-timezone').with({
          :command => "clock format show-timezone syslog"
        })
        is_expected.to contain_cisco_command_config('no-clock-summer-time').with({
          :command => "no clock summer-time"
        })
        is_expected.to contain_cisco_command_config('line-console').with({
          :command => "line console\n  exec-timeout 15\nline vty\n  session-limit 5\n  exec-timeout 15"
        })
      end
    end
    context 'call sec conditional logics for timezone' do
      let(:facts) {{
         :timezone => 'UTC'
      }}
      it  'validate when time is utc, clock is not set' do
        is_expected.not_to contain_cisco_command_config('clock-timezone').with({
         :command => "clock timezone UTC 0 0"
        })
      end
    end
    context 'call sec conditional logics for timezone' do
      let(:facts) {{
         :timezone => 'PST'
      }}
      it 'validate when is not utc, clock is set' do
        is_expected.to contain_cisco_command_config('clock-timezone').with({
          :command => "clock timezone UTC 0 0"
         })
      end
    end
  end
end
