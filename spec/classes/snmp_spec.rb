require 'spec_helper'
describe 'cisco_datacentre::snmp', :type => :class do
  let(:node) { 'nexus_switch.example.com'}
  describe 'when called with sane parameters on Cisco N9K switches' do
    let(:facts) {{
       :osfamily => 'RedHat',
       :operatingsystem => 'nexus'
    }}
    let(:params) {{
       :read_only => {
         'testread'=> {
           'testreadacl' => ['1.1.1.0/24', '2.2.2.0/24', '3.3.3.0/24']
           }
         },
       :read_write => {
         'testrw'=> {
           'testrwacl' => ['1.1.2.0/24', '2.2.3.0/24', '3.3.4.0/24']
           }
         },
       :syscontact_string => 'NOC 1-888-XXX-XXXX',
       :syslocation_string => 'Datacentre'
    }}
    it { is_expected.to contain_class('cisco_datacentre::snmp') }

    context 'call snmp class' do
      it 'read_only' do
        is_expected.to contain_cisco_acl('ipv4 testreadacl').with({
          :ensure => 'present'
        })
        is_expected.to contain_cisco_ace('ipv4 testreadacl 10').with({
          :ensure   => 'present',
          :action   => 'permit',
          :proto    => 'ip',
          :src_addr =>  '1.1.1.0/24',
          :dst_addr => 'any'
        }).that_requires('Cisco_acl[ipv4 testreadacl]')
        is_expected.to contain_cisco_ace('ipv4 testreadacl 20').with({
          :ensure   => 'present',
          :action   => 'permit',
          :proto    => 'ip',
          :src_addr =>  '2.2.2.0/24',
          :dst_addr => 'any'
        }).that_requires('Cisco_acl[ipv4 testreadacl]')
        is_expected.to contain_cisco_ace('ipv4 testreadacl 30').with({
          :ensure   => 'present',
          :action   => 'permit',
          :proto    => 'ip',
          :src_addr =>  '3.3.3.0/24',
          :dst_addr => 'any'
        }).that_requires('Cisco_acl[ipv4 testreadacl]')
        is_expected.to contain_cisco_snmp_community('testread').with({
          :ensure    => 'present',
          :community => 'testread',
          :group     => 'network-operator',
          :acl       => 'testreadacl'
        }).that_requires('Cisco_acl[ipv4 testreadacl]')
      end
      it 'read_write' do
        is_expected.to contain_cisco_acl('ipv4 testrwacl').with({
            :ensure => 'present'
        })
        is_expected.to contain_cisco_ace('ipv4 testrwacl 10').with({
          :ensure   => 'present',
          :action   => 'permit',
          :proto    => 'ip',
          :src_addr =>  '1.1.2.0/24',
          :dst_addr => 'any'
        }).that_requires('Cisco_acl[ipv4 testrwacl]')
        is_expected.to contain_cisco_ace('ipv4 testrwacl 20').with({
          :ensure   => 'present',
          :action   => 'permit',
          :proto    => 'ip',
          :src_addr =>  '2.2.3.0/24',
          :dst_addr => 'any'
        }).that_requires('Cisco_acl[ipv4 testrwacl]')
        is_expected.to contain_cisco_ace('ipv4 testrwacl 30').with({
          :ensure   => 'present',
          :action   => 'permit',
          :proto    => 'ip',
          :src_addr =>  '3.3.4.0/24',
          :dst_addr => 'any'
        }).that_requires('Cisco_acl[ipv4 testrwacl]')
        is_expected.to contain_cisco_snmp_community('testrw').with({
          :ensure    => 'present',
          :community => 'testrw',
          :group     => 'network-operator',
          :acl       => 'testrwacl'
        }).that_requires('Cisco_acl[ipv4 testrwacl]')
      end
      it 'provide contacts and location' do
        is_expected.to contain_cisco_snmp_server('default').with({
          :location => 'Datacentre',
          :contact   => 'NOC 1-888-XXX-XXXX'
        })
      end
    end
  end
end
