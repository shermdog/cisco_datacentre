require 'spec_helper'
describe 'rbc_cisco_datacentre::evpn::underlayvlan', :type => :define do
  let(:title) { '123' }
  describe 'When declared' do
    let(:params) {{
      :vlan_id          => 123,
      :vlan_name        => 'test123',
      :vlan_ip          => '10.1.2.3',
      :vlan_mask        => 24,
      :vlan_vip         => '10.1.2.1',
      :ospf_area_id     => '0.1.2.3',
    }}

    it { is_expected.to compile }
    it { is_expected.to have_resource_count(5) }
    context 'with typical params' do
      it 'applies resources' do
        is_expected.to contain_cisco_vlan('123').with({
          :ensure => 'present',
          :vlan_name => 'test123',
          :state      => 'active',
          :shutdown   => false,
        })
        is_expected.to contain_cisco_interface('Vlan123').with({
          :ensure                            => 'present',
          :interface                         => "Vlan123",
          :description                       => 'test123',
          :shutdown                          => false,
          :ipv4_address                      => '10.1.2.3',
          :ipv4_netmask_length               => 24,
          :ipv4_redirects                    => false,
          :ipv4_arp_timeout                  => 300,
          :ipv4_pim_sparse_mode              => true,
          :pim_bfd                           => true,
        })
        is_expected.to contain_cisco_interface_ospf('Vlan123 UNDERLAY').with({
          :ensure            => 'present',
          :interface         => 'Vlan123',
          :bfd               => true,
          :ospf              => 'UNDERLAY',
          :area              => '0.1.2.3',
          :cost              => 90,
          :passive_interface => true,
        })
        is_expected.to contain_cisco_interface_hsrp_group('vlan123 1 ipv4').with({
          :ensure      => 'present',
          :ipv4_enable => true,
          :ipv4_vip    => '10.1.2.1',
          :priority    => 200,
          :preempt     => true,
        })
      end
    end
    context 'with dhcp params' do
      let(:params) {{
        :vlan_id          => 123,
        :vlan_name        => 'test123',
        :vlan_ip          => '10.1.2.3',
        :vlan_mask        => 24,
        :vlan_vip         => '10.1.2.1',
        :ospf_area_id     => '0.1.2.3',
        :dhcp_servers     => ['1.1.1.1']
      }}
      it 'applies resources' do
        is_expected.to contain_cisco_vlan('123').with({
          :ensure => 'present',
          :vlan_name => 'test123',
          :state      => 'active',
          :shutdown   => false,
        })
        is_expected.to contain_cisco_interface('Vlan123').with({
          :ensure                            => 'present',
          :interface                         => "Vlan123",
          :description                       => 'test123',
          :shutdown                          => false,
          :ipv4_address                      => '10.1.2.3',
          :ipv4_netmask_length               => 24,
          :ipv4_redirects                    => false,
          :ipv4_arp_timeout                  => 300,
          :ipv4_dhcp_relay_addr              => ['1.1.1.1'],
          :ipv4_pim_sparse_mode              => true,
          :pim_bfd                           => true,
        })
        is_expected.to contain_cisco_interface_ospf('Vlan123 UNDERLAY').with({
          :ensure            => 'present',
          :interface         => 'Vlan123',
          :bfd               => true,
          :ospf              => 'UNDERLAY',
          :area              => '0.1.2.3',
          :cost              => 90,
          :passive_interface => true,
        })
        is_expected.to contain_cisco_interface_hsrp_group('vlan123 1 ipv4').with({
          :ensure      => 'present',
          :ipv4_enable => true,
          :ipv4_vip    => '10.1.2.1',
          :priority    => 200,
          :preempt     => true,
        })
      end
    end
  end
end
