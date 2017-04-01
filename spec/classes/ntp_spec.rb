require 'spec_helper'
describe 'cisco_datacentre::ntp', :type => :class do
  let(:node) { 'sb1sf01lf01.devfg.rbc.com' }
  describe 'when called with sane parameters on Cisco N9K switches' do
    let(:facts) {{
       :osfamily => 'RedHat',
       :operatingsystem => 'nexus'
    }}
    let(:params) {{
       :ntpservers => ['10.1.1.1', '10.2.2.2']
    }}
    it { is_expected.to contain_class('cisco_datacentre::ntp') }

    context 'call ntp class with test array' do
      let(:params) {{
         :ntpservers => ['10.1.1.1', '10.2.2.2']
      }}
      it 'create the ntp acl' do
        is_expected.to contain_cisco_acl('ipv4 NTP_ACL').with({
          :ensure => 'present'
        })
      end
      it 'add valid ntp acl entries' do
        is_expected.to contain_cisco_ace('ipv4 NTP_ACL 10').with({
          :ensure   => 'present',
          :action   => 'permit',
          :proto    => 'ip',
          :src_addr => "10.1.1.1/32",
          :dst_addr => 'any'
        }).that_requires('Cisco_acl[ipv4 NTP_ACL]')
        is_expected.to contain_cisco_ace('ipv4 NTP_ACL 20').with({
          :ensure   => 'present',
          :action   => 'permit',
          :proto    => 'ip',
          :src_addr => "10.2.2.2/32",
          :dst_addr => 'any'
        }).that_requires('Cisco_acl[ipv4 NTP_ACL]')
      end
      it 'enable ntp server via cli' do
        is_expected.to contain_cisco_command_config('ntp-server-0').with({
          :command => "ntp server 10.1.1.1 use-vrf management"
        })
        is_expected.to contain_cisco_command_config('ntp-server-1').with({
          :command => "ntp server 10.2.2.2 use-vrf management"
        })
      end
      it 'applies the acl via cli' do
        is_expected.to contain_cisco_command_config('ntp-server-acl').with({
          :command => "ntp access-group peer NTP_ACL"
        })
      end
    end

    context 'call ntp class with bad array' do
      let(:params) {{
         :ntpservers => ['10.1.1.1000', '10.2.2.2']
      }}
      it do
        expect {
          is_expected.to contain_cisco_acl('ipv4 NTP_ACL').with({
            :ensure => 'present'
          })
          is_expected.to contain_cisco_ace('ipv4 NTP_ACL 10').with({
            :ensure   => 'present',
            :action   => 'permit',
            :proto    => 'ip',
            :src_addr => "10.1.1.1000/32",
            :dst_addr => 'any'
          })
        }.to raise_error(Puppet::ParseError, /is not a valid IP address/)
      end
    end
  end
end
