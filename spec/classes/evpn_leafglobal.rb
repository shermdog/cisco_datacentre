require 'spec_helper'
describe 'cisco_datacentre::evpn::leafglobal', :type => :class do
  let(:node) { 'nexus_switch.example.com' }
  describe 'When declared' do
    let(:facts) {{
      :osfamily        => 'RedHat',
      :operatingsystem => 'nexus'
    }}

    it { is_expected.to contain_class('cisco_datacentre::evpn::leafglobal') }

    context 'includes settings for' do
      it 'bfd' do
        is_expected.to contain_cisco_bfd_global('default').with({
          :ensure        => 'present',
          :ipv4_interval => [ 150, 150, 3 ],
          :startup_timer => 0
        })
      end
      it 'stp' do
        is_expected.to contain_cisco_stp_global('default').with({
          :mode          => 'rapid-pvst',
          :bpduguard     => true,
          :pathcost      => 'long',
          :vlan_priority => [ [ '1-3967', '24576' ] ]
        })
      end
      it 'nv overlay' do
        is_expected.to contain_cisco_overlay_global('default').with({
          :anycast_gateway_mac                   => '0200.fab0.0001',
          :dup_host_ip_addr_detection_host_moves => 5,
          :dup_host_ip_addr_detection_timeout    => 180
        })
      end
    end
    context 'with parameter' do
      let(:params) {{
        :anycast_mac => '1234.5678.9abc',
      }}
      it 'sets anycast_mac for nv overlay' do
        is_expected.to contain_cisco_overlay_global('default').with({
          :anycast_gateway_mac                   => '1234.5678.9abc',
          :dup_host_ip_addr_detection_host_moves => 5,
          :dup_host_ip_addr_detection_timeout    => 180
        })
      end
    end
  end
end
