require 'spec_helper'
describe 'cisco_datacentre::evpn::leafoverlay', :type => :class do
  let(:node) { 'nexus_switch.example.com' }
  describe 'When declared' do
    let(:facts) {{
      :osfamily        => 'RedHat',
      :operatingsystem => 'nexus'
    }}
    let(:params) {{
      :bgp_asn          => '65501',
      :vxlan_vni_prefix => '501',
      :vxlan_vrf        => 'test',
      :loopback0_ip     => '10.0.0.1',
      :loopback1_ip     => '10.0.1.1',
      :loopback1_vtepip => '10.0.1.101',
      :spine_bgp_peers  => {
        '10.1.1.1' => 'spine1',
        '10.1.1.2' => 'spine2'
      }
    }}

    it { is_expected.to contain_class('cisco_datacentre::evpn::leafoverlay') }

    context 'includes LF settings for' do
      let(:facts) {{
        :function => 'leaf'
      }}
      it 'loopback1' do
        is_expected.to contain_cisco_interface('loopback1').with({
          :ensure                        => 'present',
          :interface                     => 'loopback1',
          :shutdown                      => false,
          :description                   => 'VTEP source interface',
          :ipv4_address                  => '10.0.1.1',
          :ipv4_netmask_length           => 32,
          :ipv4_address_secondary        => '10.0.1.101',
          :ipv4_netmask_length_secondary => 32,
          :ipv4_pim_sparse_mode          => true,
        })
      end
      it 'vxlan vrf & af' do
        is_expected.to contain_cisco_vrf('test').with({
          :ensure              => 'present',
          :description         => 'VXLAN VRF test',
          :route_distinguisher => 'auto',
        })
        is_expected.to contain_cisco_vrf_af('test ipv4 unicast').with({
          :ensure                      => 'present',
          :route_target_both_auto_evpn => true,
          :route_target_both_auto      => true
        })
      end
      it 'l3vni vlan & svi' do
        is_expected.to contain_cisco_vlan('10').with({
          :ensure     => 'present',
          :mapped_vni => '5010010',
          :vlan_name  => 'L3VNI',
          :state      => 'active',
          :shutdown   => false,
        })
        is_expected.to contain_cisco_interface('Vlan10').with({
         :ensure          => 'present',
         :interface       => 'Vlan10',
         :shutdown        => false,
         :description     => 'L3VNI',
         :mtu             => 9216,
         :vrf             => 'test',
         :ipv4_forwarding => true
        }).that_requires('[Cisco_vlan["10"],Cisco_vrf["test"]]')
      end
      it 'nv vtep' do
        is_expected.to contain_cisco_vxlan_vtep('nve1').with({
          :ensure                          => 'present',
          :description                     => 'NVE overlay interface',
          :host_reachability               => 'evpn',
          :shutdown                        => false,
          :source_interface                => 'loopback1',
          :source_interface_hold_down_time => 360,
        })
        is_expected.to contain_cisco_vxlan_vtep_vni('nve1 5010010').with({
          :ensure    => 'present',
          :assoc_vrf => true,
        }).that_requires('Cisco_vlan[10]')
      end
      it 'bgp global' do
        is_expected.to contain_cisco_bgp('65501 default').with({
          :ensure               => present,
          :router_id            => '10.0.0.1',
          :log_neighbor_changes => true,
        })
      end
      it 'bgp neighbors' do
        is_expected.to contain_cisco_bgp_neighbor('65501 default 10.1.1.1').with({
          :ensure        => 'present',
          :description   => 'spine1',
          :bfd           => true,
          :remote_as     => '65501',
          :update_source => 'loopback0',
          :password      => '9125d59c18a9b015',
          :password_type => '3des'
        })
        is_expected.to contain_cisco_bgp_neighbor('65501 default 10.2.2.2').with({
          :ensure        => 'present',
          :description   => 'spine2',
          :bfd           => true,
          :remote_as     => '65501',
          :update_source => 'loopback0',
          :password      => '9125d59c18a9b015',
          :password_type => '3des'
        })
        is_expected.to contain_cisco_bgp_neighbor_af('65501 default 10.2.2.2 l2vpn evpn').with({
          :ensure                  => 'present',
          :send_community          => 'both',
          :soft_reconfiguration_in => 'always'
        })
      end
      it 'absent bgp vxlan vrf AF' do
        is_expected.to contain_cisco_bgp_af('65501 test').with({
          :ensure => 'absent'
        })
      end
    end
    context 'includes BL settings for' do
      let(:params) {{
        :bgp_asn          => '65501',
        :vxlan_vni_prefix => '501',
        :vxlan_vrf        => 'test',
        :loopback0_ip     => '10.0.0.1',
        :loopback1_ip     => '10.0.1.1',
        :spine_bgp_peers  => {
          '10.1.1.1' => 'spine1',
          '10.1.1.2' => 'spine2'
        }
      }}
      it 'loopback1 without secondary IP' do
        is_expected.to contain_cisco_interface('loopback1').with({
          :ensure                        => 'present',
          :interface                     => 'loopback1',
          :shutdown                      => false,
          :description                   => 'VTEP source interface',
          :ipv4_address                  => '10.0.1.1',
          :ipv4_netmask_length           => 32,
          :ipv4_pim_sparse_mode          => true,
        })
      end
    end
  end
end
