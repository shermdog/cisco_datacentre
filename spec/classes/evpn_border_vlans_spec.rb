require 'spec_helper'
describe 'cisco_datacentre::evpn::border_vlans', :type => :class do
  let(:node) { 'nexus_switch.example.com' }
  describe 'When declared' do
    let(:facts) {{
      :osfamily        => 'RedHat',
      :operatingsystem => 'nexus'
    }}
    let(:params) {{
      :vxlan_vrf => 'test',
      :vxlan_vni_prefix => 123,
      :vlans => {
        11 => {
          'name' => 'test11',
          'ip' => '10.11.0.1',
          'mask' => 24,
          'multicast_group' => '239.96.0.11',
        },
        12 => {
          'name' => 'test12',
          'ip' => '10.12.0.1',
          'mask' => 24,
          'multicast_group' => '239.96.0.12',
          'dhcp_enabled' => true,
          'dhcp_servers' => 'DEV',
        },
        13 => {
          'name' => 'test13',
          'ip' => '10.13.0.1',
          'mask' => 24,
          'multicast_group' => '239.96.0.13',
          'dhcp_enabled' => true,
          'dhcp_servers' => 'QA',
        },
        14 => {
          'name' => 'test14',
          'ip' => '10.14.0.1',
          'mask' => 24,
          'multicast_group' => '239.96.0.14',
          'dhcp_enabled' => true,
          'dhcp_servers' => 'prod',
        },
      },
      :dev_dhcp_servers => ['1.1.1.1', '1.1.1.2'],
      :qa_dhcp_servers => ['1.1.1.3', '1.1.1.4'],
      :prod_dhcp_servers => ['1.1.1.5'],
    }}

    it { is_expected.to compile }
    it { is_expected.to contain_class('cisco_datacentre::evpn::border_vlans') }
    it { is_expected.to have_resource_count(21) }

    it 'applies dhcp global settings' do
      is_expected.to contain_cisco_dhcp_relay_global('default').with({
        :ipv4_relay                  => true,
        :ipv4_information_option     => true,
        :ipv4_information_option_vpn => true,
        :ipv4_sub_option_cisco       => true
      })
    end
    it 'applies overlayvlan defined type' do
      is_expected.to contain_cisco_datacentre__evpn__overlayvlan('11').with({
        :vlan_id          => 11,
        :vlan_name        => 'test11',
        :vlan_ip          => '10.11.0.1',
        :vlan_mask        => 24,
        :vlan_mcast_group => '239.96.0.11',
        :vlan_vni         => 1230011,
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
    it 'applies overlayvlan w/ DEV dhcp' do
      is_expected.to contain_cisco_datacentre__evpn__overlayvlan('12').with({
        :vlan_id          => 12,
        :vlan_name        => 'test12',
        :vlan_ip          => '10.12.0.1',
        :vlan_mask        => 24,
        :vlan_mcast_group => '239.96.0.12',
        :vlan_vni         => 1230012,
        :vxlan_vrf        => 'test',
        :dhcp_servers     => ['1.1.1.1', '1.1.1.2'],
      })
      is_expected.to contain_cisco_vlan('12').with({
        :ensure => 'present',
        :vlan_name => 'test12',
        :mapped_vni => '1230012',
        :state      => 'active',
        :shutdown   => false,
      })
      is_expected.to contain_cisco_vxlan_vtep_vni('nve1 1230012').with({
        :ensure => 'present',
        :assoc_vrf       => false,
        :multicast_group => '239.96.0.12',
        :suppress_arp    => true,
      })
      is_expected.to contain_cisco_evpn_vni('1230012').with({
        :ensure => 'present',
        :route_distinguisher => 'auto',
        :route_target_import => 'auto',
        :route_target_export => 'auto',
      })
      is_expected.to contain_cisco_interface('Vlan12').with({
        :ensure                            => 'present',
        :interface                         => "Vlan12",
        :description                       => 'test12',
        :shutdown                          => false,
        :mtu                               => 9216,
        :vrf                               => 'test',
        :ipv4_address                      => '10.12.0.1',
        :ipv4_netmask_length               => 24,
        :ipv4_redirects                    => false,
        :ipv4_arp_timeout                  => 300,
        :ipv4_dhcp_relay_addr => ['1.1.1.1','1.1.1.2'],
        :fabric_forwarding_anycast_gateway => true,
      }).that_requires('Cisco_dhcp_relay_global[default]')
    end
    it 'applies overlayvlan w/ QA dhcp' do
      is_expected.to contain_cisco_datacentre__evpn__overlayvlan('13').with({
        :vlan_id          => 13,
        :vlan_name        => 'test13',
        :vlan_ip          => '10.13.0.1',
        :vlan_mask        => 24,
        :vlan_mcast_group => '239.96.0.13',
        :vlan_vni         => 1230013,
        :vxlan_vrf        => 'test',
        :dhcp_servers     => ['1.1.1.3', '1.1.1.4'],
      })
      is_expected.to contain_cisco_vlan('13').with({
        :ensure => 'present',
        :vlan_name => 'test13',
        :mapped_vni => '1230013',
        :state      => 'active',
        :shutdown   => false,
      })
      is_expected.to contain_cisco_vxlan_vtep_vni('nve1 1230013').with({
        :ensure => 'present',
        :assoc_vrf       => false,
        :multicast_group => '239.96.0.13',
        :suppress_arp    => true,
      })
      is_expected.to contain_cisco_evpn_vni('1230013').with({
        :ensure => 'present',
        :route_distinguisher => 'auto',
        :route_target_import => 'auto',
        :route_target_export => 'auto',
      })
      is_expected.to contain_cisco_interface('Vlan13').with({
        :ensure                            => 'present',
        :interface                         => "Vlan13",
        :description                       => 'test13',
        :shutdown                          => false,
        :mtu                               => 9216,
        :vrf                               => 'test',
        :ipv4_address                      => '10.13.0.1',
        :ipv4_netmask_length               => 24,
        :ipv4_redirects                    => false,
        :ipv4_arp_timeout                  => 300,
        :ipv4_dhcp_relay_addr => ['1.1.1.3','1.1.1.4'],
        :fabric_forwarding_anycast_gateway => true,
      }).that_requires('Cisco_dhcp_relay_global[default]')
    end
    it 'applies overlayvlan w/ prod dhcp' do
      is_expected.to contain_cisco_datacentre__evpn__overlayvlan('14').with({
        :vlan_id          => 14,
        :vlan_name        => 'test14',
        :vlan_ip          => '10.14.0.1',
        :vlan_mask        => 24,
        :vlan_mcast_group => '239.96.0.14',
        :vlan_vni         => 1230014,
        :vxlan_vrf        => 'test',
        :dhcp_servers     => ['1.1.1.5'],
      })
      is_expected.to contain_cisco_vlan('14').with({
        :ensure => 'present',
        :vlan_name => 'test14',
        :mapped_vni => '1230014',
        :state      => 'active',
        :shutdown   => false,
      })
      is_expected.to contain_cisco_vxlan_vtep_vni('nve1 1230014').with({
        :ensure => 'present',
        :assoc_vrf       => false,
        :multicast_group => '239.96.0.14',
        :suppress_arp    => true,
      })
      is_expected.to contain_cisco_evpn_vni('1230014').with({
        :ensure => 'present',
        :route_distinguisher => 'auto',
        :route_target_import => 'auto',
        :route_target_export => 'auto',
      })
      is_expected.to contain_cisco_interface('Vlan14').with({
        :ensure                            => 'present',
        :interface                         => "Vlan14",
        :description                       => 'test14',
        :shutdown                          => false,
        :mtu                               => 9216,
        :vrf                               => 'test',
        :ipv4_address                      => '10.14.0.1',
        :ipv4_netmask_length               => 24,
        :ipv4_redirects                    => false,
        :ipv4_arp_timeout                  => 300,
        :ipv4_dhcp_relay_addr => ['1.1.1.5'],
        :fabric_forwarding_anycast_gateway => true,
      }).that_requires('Cisco_dhcp_relay_global[default]')
    end
  end
end
