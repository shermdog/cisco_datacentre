require 'spec_helper'
describe 'cisco_datacentre::vpc', :type => :class do
  let(:node) { 'nexus_switch.example.com' }
  describe 'Class Vpc declared with sane parameters' do
    let(:facts) {{
      :osfamily => 'RedHat',
      :operatingsystem => 'nexus'
    }}
    let(:params) {{
      :peer_keepalive_src => '10.1.1.1',
      :peer_keepalive_dest => '10.1.1.2',
      :primary => true,
      :domain  => 100
    }}

    it { is_expected.to contain_class('cisco_datacentre::vpc') }

    context 'apply configuration of vpc' do
      it 'domain for primary role' do
        is_expected.to contain_cisco_vpc_domain('100').with({
          :ensure                       => 'present',
          :role_priority                => 2000,
          :system_priority              => 2000,
          :peer_keepalive_dest          => '10.1.1.2',
          :peer_keepalive_src           => '10.1.1.1',
          :peer_keepalive_vrf           => 'management',
          :delay_restore                => 240,
          :delay_restore_interface_vlan => 240,
          :peer_gateway                 => true,
          :auto_recovery                => true,
        })
      end
    end
    context 'apply configuration for 2nd vpc' do
      let(:params) {{
        :peer_keepalive_src => '10.1.1.1',
        :peer_keepalive_dest => '10.1.1.2',
        :primary => false,
        :domain  => 100
      }}
      it 'domain for secondary role' do
        is_expected.to contain_cisco_vpc_domain('100').with({
          :ensure                       => 'present',
          :system_priority              => 2000,
          :peer_keepalive_dest          => '10.1.1.2',
          :peer_keepalive_src           => '10.1.1.1',
          :peer_keepalive_vrf           => 'management',
          :delay_restore                => 240,
          :delay_restore_interface_vlan => 240,
          :peer_gateway                 => true,
          :auto_recovery                => true,
        })
      end
    end
    context 'interface configuration' do
      it 'peerlink' do
        is_expected.to contain_cisco_interface('port-channel100').with({
          :ensure                  => 'present',
          :description             => 'vPC Peerlink',
          :switchport_mode         => 'trunk',
          :vpc_peer_link           => true,
          :stp_port_type           => 'network',
          :storm_control_broadcast => '90.00',
          :storm_control_multicast => '90.00',
          :shutdown                => false,
        }).that_requires('Cisco_vpc_domain[100]')
      end
      it 'peerlink member interfaces' do
        is_expected.to contain_cisco_interface('Ethernet1/53').with({
            :ensure                  => 'present',
            :description             => "vPC Peerlink Po100",
            :switchport_mode         => 'trunk',
            :stp_port_type           => 'network',
            :storm_control_broadcast => '90.00',
            :storm_control_multicast => '90.00',
            :shutdown                => false,
        })
        is_expected.to contain_cisco_interface('Ethernet1/54').with({
            :ensure                  => 'present',
            :description             => "vPC Peerlink Po100",
            :switchport_mode         => 'trunk',
            :stp_port_type           => 'network',
            :storm_control_broadcast => '90.00',
            :storm_control_multicast => '90.00',
            :shutdown                => false,
        })
      end
      it 'peerlink member channel_group' do
        is_expected.to contain_cisco_interface_channel_group('Ethernet1/53').with({
            :ensure                  => 'present',
            :interface               => 'Ethernet1/53',
            :channel_group           => '100',
        })
        is_expected.to contain_cisco_interface_channel_group('Ethernet1/54').with({
            :ensure                  => 'present',
            :interface               => 'Ethernet1/54',
            :channel_group           => '100',
        })
      end
    end
  end
end
