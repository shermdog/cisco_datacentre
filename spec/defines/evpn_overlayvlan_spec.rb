require 'spec_helper'
describe 'rbc_cisco_datacentre::evpn::overlayvlan', :type => :define do
  let(:node) { 'nexus_switch.example.com' }
  let(:title) { '123' }
  describe 'When declared with typical params' do
    let(:params) {{
      :vlan_id          => 123,
      :vlan_name        => 'test123',
      :vlan_ip          => '10.1.2.3',
      :vlan_mask        => 24,
      :vlan_mcast_group => '239.96.0.123',
      :vlan_vni         => 1230123,
      :vxlan_vrf        => 'test',
    }}

    it { is_expected.to compile }
    it { is_expected.to have_resource_count(5) }

    it 'individual resources' do
      is_expected.to contain_cisco_vlan('123').with({
        :ensure => 'present',
        :vlan_name => 'test123',
        :mapped_vni => '1230123',
        :state      => 'active',
        :shutdown   => false,
      })
      is_expected.to contain_cisco_vxlan_vtep_vni('nve1 1230123').with({
        :ensure => 'present',
        :assoc_vrf       => false,
        :multicast_group => '239.96.0.123',
        :suppress_arp    => true,
      })
      is_expected.to contain_cisco_evpn_vni('1230123').with({
        :ensure => 'present',
        :route_distinguisher => 'auto',
        :route_target_import => 'auto',
        :route_target_export => 'auto',
      })
      is_expected.to contain_cisco_interface('Vlan123').with({
        :ensure                            => 'present',
        :interface                         => "Vlan123",
        :description                       => 'test123',
        :shutdown                          => false,
        :mtu                               => 9216,
        :vrf                               => 'test',
        :ipv4_address                      => '10.1.2.3',
        :ipv4_netmask_length               => 24,
        :ipv4_redirects                    => false,
        :ipv4_arp_timeout                  => 300,
        :fabric_forwarding_anycast_gateway => true,
      })
    end
    context 'w/ dhcp' do
      let(:pre_condition) { "cisco_dhcp_relay_global { 'default': ipv4_relay => true}"}
      let(:params) {{
        :vlan_id          => 123,
        :vlan_name        => 'test123',
        :vlan_ip          => '10.1.2.3',
        :vlan_mask        => 24,
        :vlan_mcast_group => '239.96.0.123',
        :vlan_vni         => 1230123,
        :vxlan_vrf        => 'test',
        :dhcp_servers     => ['1.1.1.1', '1.1.1.2']
      }}
      it 'includes resources' do
        is_expected.to contain_cisco_vlan('123').with({
          :ensure => 'present',
          :vlan_name => 'test123',
          :mapped_vni => '1230123',
          :state      => 'active',
          :shutdown   => false,
        })
        is_expected.to contain_cisco_vxlan_vtep_vni('nve1 1230123').with({
          :ensure => 'present',
          :assoc_vrf       => false,
          :multicast_group => '239.96.0.123',
          :suppress_arp    => true,
        })
        is_expected.to contain_cisco_evpn_vni('1230123').with({
          :ensure => 'present',
          :route_distinguisher => 'auto',
          :route_target_import => 'auto',
          :route_target_export => 'auto',
        })
        is_expected.to contain_cisco_interface('Vlan123').with({
          :ensure                            => 'present',
          :interface                         => "Vlan123",
          :description                       => 'test123',
          :shutdown                          => false,
          :mtu                               => 9216,
          :vrf                               => 'test',
          :ipv4_address                      => '10.1.2.3',
          :ipv4_netmask_length               => 24,
          :ipv4_redirects                    => false,
          :ipv4_arp_timeout                  => 300,
          :ipv4_dhcp_relay_addr              => ['1.1.1.1', '1.1.1.2'],
          :fabric_forwarding_anycast_gateway => true,
        }).that_requires('Cisco_dhcp_relay_global[default]')
      end
    end
  end
end
