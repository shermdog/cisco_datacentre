require 'spec_helper'
describe 'cisco_datacentre::syslog', :type => :class do
  let(:node) { 'nexus_switch.example.com'}
  describe 'when called with sane parameters on Cisco N9K switches' do
    let(:facts) {{
      :osfamily => 'RedHat',
      :operatingsystem => 'nexus'
    }}
    let(:params) {{
      :syslog_servers => ['10.1.1.1', '10.2.2.2', '10.3.3.3']
    }}

    it { is_expected.to contain_class('cisco_datacentre::syslog') }

    context 'configure each syslog server' do
      it 'first configuration' do
        is_expected.to contain_cisco_command_config('syslog_10.1.1.1').with({
          :command => 'logging server 10.1.1.1 use-vrf management'
        })
      end
      it 'second configuration' do
        is_expected.to contain_cisco_command_config('syslog_10.2.2.2').with({
          :command => 'logging server 10.2.2.2 use-vrf management'
        })
      end
      it 'third configuration' do
        is_expected.to contain_cisco_command_config('syslog_10.3.3.3').with({
          :command => 'logging server 10.3.3.3 use-vrf management'
        })
      end
    end
    context 'configure syslog with non-default VRF' do
      let(:params) {{
        :syslog_servers => ['10.1.1.1'],
        :syslog_vrf     => 'testvrf1'
      }}
      it 'command' do
        is_expected.to contain_cisco_command_config('syslog_10.1.1.1').with({
          :command => 'logging server 10.1.1.1 use-vrf testvrf1'
        })
      end
    end
  end
end
