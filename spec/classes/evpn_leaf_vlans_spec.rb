require 'spec_helper'
describe 'cisco_datacentre::evpn::leaf_vlans', :type => :class do
  let(:node) { 'nexus_switch.example.com' }
  describe 'When declared' do
    let(:facts) {{
      :osfamily        => 'RedHat',
      :operatingsystem => 'nexus'
    }}
    let(:params) {{
      :vxlan_vrf => 'test',
      :vxlan_vni_prefix => 123,
      :ospf_area_id => '0.0.0.1',
      :vlans => {
        11 => {
          'name' => 'test11',
          'ip' => '10.11.0.1',
          'mask' => 24,
          'multicast_group' => '239.96.0.11'
        },
        12 => {
          'name' => 'test12',
          'ip' => '10.12.0.2',
          'mask' => 24,
          'vip' => '10.12.0.1',
        },
        13 => 'test13',
      }
    }}

    it { is_expected.to compile }
    it { is_expected.to contain_class('cisco_datacentre::evpn::leaf_vlans') }
    it { is_expected.to have_resource_count(12) }

    it 'overlay example VLAN11' do
      is_expected.to contain_cisco_datacentre__evpn__overlayvlan('11').with({
        :vlan_id          => 11,
        :vlan_name        => 'test11',
        :vlan_ip          => '10.11.0.1',
        :vlan_mask        => 24,
        :vlan_mcast_group => '239.96.0.11',
        :vlan_vni         => '1230011',
        :vxlan_vrf        => 'test',
      })
      is_expected.to contain_cisco_vlan('11').with({
        :ensure => 'present',
        :vlan_name => 'test11',
        :mapped_vni => '1230011',
        :state      => 'active',
        :shutdown   => false,
      })
      is_expected.to contain_cisco_vxlan_vtep_vni('nve1 1230011').with({
        :ensure => 'present',
        :assoc_vrf       => false,
        :multicast_group => '239.96.0.11',
        :suppress_arp    => true,
      })
      is_expected.to contain_cisco_evpn_vni('1230011').with({
        :ensure => 'present',
        :route_distinguisher => 'auto',
        :route_target_import => 'auto',
        :route_target_export => 'auto',
      })
      is_expected.to contain_cisco_interface('Vlan11').with({
        :ensure                            => 'present',
        :interface                         => "Vlan11",
        :description                       => 'test11',
        :shutdown                          => false,
        :mtu                               => 9216,
        :vrf                               => 'test',
        :ipv4_address                      => '10.11.0.1',
        :ipv4_netmask_length               => 24,
        :ipv4_redirects                    => false,
        :ipv4_arp_timeout                  => 300,
        :fabric_forwarding_anycast_gateway => true,
      })
    end
    it 'underlay example VLAN12' do
      is_expected.to contain_cisco_datacentre__evpn__underlayvlan('12').with({
        :vlan_id          => 12,
        :vlan_name        => 'test12',
        :vlan_ip          => '10.12.0.2',
        :vlan_mask        => 24,
        :vlan_vip         => '10.12.0.1',
        :ospf_area_id     => '0.0.0.1',
        :hsrp_primary     => true,
      })
      is_expected.to contain_cisco_vlan('12').with({
        :ensure    => 'present',
        :vlan_name => 'test12',
        :state     => 'active',
        :shutdown  => false,
      })
      is_expected.to contain_cisco_interface('Vlan12').with({
        :ensure               => 'present',
        :interface            => 'Vlan12',
        :description          => 'test12',
        :shutdown             => false,
        :ipv4_address         => '10.12.0.2',
        :ipv4_netmask_length  => 24,
        :ipv4_redirects       => false,
        :ipv4_arp_timeout     => 300,
        :ipv4_pim_sparse_mode => true,
        :pim_bfd              => true,
      })
      is_expected.to contain_cisco_interface_ospf('Vlan12 UNDERLAY').with({
        :ensure            => 'present',
        :interface         => 'Vlan12',
        :bfd               => true,
        :ospf              => 'UNDERLAY',
        :area              => '0.0.0.1',
        :cost              => 90,
        :passive_interface => true,
      })
      is_expected.to contain_cisco_interface_hsrp_group('vlan12 1 ipv4').with({
        :ensure      => 'present',
        :ipv4_enable => true,
        :ipv4_vip    => '10.12.0.1',
        :priority    => 200,
        :preempt     => true,
      })
    end
    it 'layer2 example VLAN13' do
      is_expected.to contain_cisco_datacentre__evpn__layer2vlan('13').with({
        :vlan_id => 13,
        :vlan_name => 'test13'
      })
      is_expected.to contain_cisco_vlan('13').with({
        :ensure    => 'present',
        :vlan_name => 'test13',
        :state     => 'active',
        :shutdown  => false,
      })
    end
  end
end
