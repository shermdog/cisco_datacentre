require 'spec_helper'
describe 'cisco_datacentre::userports', :type => :class do
  let(:node) { 'nexus_switch.example.com' }
  describe 'Class Userports declared with sane parameters' do
    let(:facts) {{
      :osfamily => 'RedHat',
      :operatingsystem => 'nexus'
    }}
    let(:params) {{
      :user_interfaces => {
        'Ethernet1/1' => 'Unused_interface',
        'Ethernet1/2' => {
          'description' => 'Access_port_Eth1/2_Vlan101',
          'access_vlan' => '101'
        },
        'Ethernet1/3' => {
          'description' => 'Trunk_port_Eth1/3_Vlans102-105',
          'allowed_vlans' => '102-105',
        },
        'Ethernet1/4' => {
          'description' => 'vPC_Po101_Eth1/4_Vlans106-110',
          'allowed_vlans' => '106-110',
          'vpc_id' => '101',
        }
      }
    }}

    it { is_expected.to contain_class('cisco_datacentre::userports') }

    context 'apply interface configurations' do
      it 'for unused interface' do
        is_expected.to contain_cisco_interface('Ethernet1/1').with({
          :ensure      => 'present',
          :interface   => 'Ethernet1/1',
          :description => 'Unused_interface',
          :shutdown    => true
        })
      end
      it 'for access interface' do
        is_expected.to contain_cisco_interface('Ethernet1/2').with({
          :ensure          => 'present',
          :interface       => 'Ethernet1/2',
          :description     => 'Access_port_Eth1/2_Vlan101',
          :shutdown        => false,
          :switchport_mode => 'access',
          :access_vlan     => 101
        })
      end
      it 'for trunk/tagged interface' do
        is_expected.to contain_cisco_interface('Ethernet1/3').with({
          :ensure                        => 'present',
          :interface                     => 'Ethernet1/3',
          :description                   => 'Trunk_port_Eth1/3_Vlans102-105',
          :shutdown                      => false,
          :switchport_mode               => 'trunk',
          :switchport_trunk_allowed_vlan => '102-105'
        })
      end
      it 'for downstream vPC port-channels' do
        is_expected.to contain_cisco_interface('Ethernet1/4').with({
          :ensure                        => 'present',
          :interface                     => 'Ethernet1/4',
          :description                   => 'vPC_Po101_Eth1/4_Vlans106-110',
          :shutdown                      => false,
          :switchport_mode               => 'trunk',
          :switchport_trunk_allowed_vlan => '106-110',
        })
        is_expected.to contain_cisco_interface('port-channel101').with({
          :ensure                        => 'present',
          :interface                     => 'port-channel101',
          :description                   => 'vPC_Po101_Eth1/4_Vlans106-110',
          :shutdown                      => false,
          :switchport_mode               => 'trunk',
          :switchport_trunk_allowed_vlan => '106-110',
          :vpc_id                        => 101
        })
        is_expected.to contain_cisco_interface_channel_group('Ethernet1/4-Po101').with({
          :interface          => 'Ethernet1/4',
          :channel_group      => 101,
        }).that_requires('Cisco_interface[port-channel101]')
      end
    end
    context 'expect failure with bad params for user_interfaces hash' do
      let(:params) {{
        :user_interfaces => {
          'Ethernet1/5' => {
          'name' => 'bad_hash_key',
          'vlans' => 'all',
          }
        }
      }}
      it do
        expect {
          is_expected.to contain_cisco_interface('Ethernet1/5')
        }.to raise_error(Puppet::ParseError, /Invalid Hiera data obtained/)
      end
    end
  end
end
