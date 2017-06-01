require 'spec_helper'
describe 'cisco_datacentre::evpn::border_interfaces', :type => :class do
  let(:node) { 'nexus_switch.example.com' }
  describe 'When declared' do
    let(:facts) {{
      :osfamily        => 'RedHat',
      :operatingsystem => 'nexus'
    }}
    let(:pre_condition) { "cisco_ospf { 'UNDERLAY': ensure => present }"}
    let(:params) {{
      :core_interfaces => {
        'ethernet1/1' => {
          'vlan_id' => '2',
          'ipaddress' => '10.0.0.1',
          'mask' => 31,
          'description' => 'core_underlay',
          'underlay' => true,
          'mtu' => 1500,
        },
        'ethernet1/2' => {
          'vlan_id' => '3',
          'ipaddress' => '10.0.1.1',
          'mask' => 31,
          'description' => 'core_overlay',
        },
        'ethernet1/3' => { 'description' => 'core'}
      },
      :ospf_area => '0.0.0.123',
      :vxlan_vrf => 'test',
    }}

    it { is_expected.to compile }
    it { is_expected.to contain_class('cisco_datacentre::evpn::border_interfaces') }
    # this class actual contains only 4 resources but had to add cisco_ospf[UNDERLAY] (see above)
    it { is_expected.to have_resource_count(5) }

    it 'underlay external interface' do
      is_expected.to contain_cisco_interface('ethernet1/1').with({
        :ensure               => 'present',
        :description          => 'core_underlay',
        :mtu                  => 1500,
        :encapsulation_dot1q  => 2,
        :ipv4_address         => '10.0.0.1',
        :ipv4_netmask_length  => 31,
        :ipv4_redirects       => false,
        :ipv4_pim_sparse_mode => true,
        :pim_bfd              => true,
        :shutdown             => false,
      })
      is_expected.to contain_cisco_interface_ospf('ethernet1/1 UNDERLAY').with({
        :ensure                         => 'present',
        :area                           => '0.0.0.123',
        :bfd                            => true,
        :network_type                   => 'p2p',
        :hello_interval                 => 3,
        :message_digest                 => true,
        :message_digest_key_id          => 1,
        :message_digest_algorithm_type  => 'md5',
        :message_digest_encryption_type => '3des',
        :message_digest_password        => 'e3b5189d66d7ed80',
      }).that_requires('Cisco_ospf[UNDERLAY]')
    end
    it 'overlay external interface' do
      is_expected.to contain_cisco_interface('ethernet1/2').with({
        :ensure              => 'present',
        :description         => 'core_overlay',
        :mtu                 => 9216,
        :encapsulation_dot1q => '3',
        :vrf                 => 'test',
        :ipv4_address        => '10.0.1.1',
        :ipv4_netmask_length => 31,
        :ipv4_redirects      => false,
        :shutdown            => false,
      })
    end
    it 'external physical interface' do
      is_expected.to contain_cisco_interface('ethernet1/3').with({
        :ensure          => 'present',
        :description     => 'core',
        :switchport_mode => 'disabled',
        :mtu             => 9216,
      })
    end
  end
end
