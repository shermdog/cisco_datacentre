require 'spec_helper'
describe 'cisco_datacentre::evpn::leafunderlay', :type => :class do
  let(:node) { 'nexus_switch.example.com' }
  describe 'When declared for Cisco Nexus switches' do
    let(:facts) {{
      :osfamily        => 'RedHat',
      :operatingsystem => 'nexus',
    }}
    let(:params) {{
      :loopback0_ip => '10.0.0.1',
      :loopback1_ip => '10.0.0.101',
      :loopback1_vtepip => '10.0.0.151',
      :ospf_area    => '0.0.0.123',
      :ptp_interfaces => {
        'ethernet1/1' => {
          'ipaddress' => '10.1.0.0',
          'description' => 'ptp_interface_1'
        },
        'ethernet1/2' => {
          'ipaddress' => '10.1.0.2',
          'description' => 'ptp_interface_2',
          'mtu' => 1500,
        }
      },
      :multicast_group_range => '239.96.0.0/24',
      :pim_anycast_rp => '10.255.0.1',
      :enterprise_pim_rp => '10.255.255.1',
      :vlan2_ip          => '10.2.0.0',
      :vlan2_description => 'underlay_vlan',
    }}

    it { is_expected.to compile }
    it { is_expected.to contain_class('cisco_datacentre::evpn::leafunderlay') }
    it { is_expected.to have_resource_count(22) }

    context 'with sane params for a leaf switch' do
      it 'creates loopback0' do
        is_expected.to contain_cisco_interface('lo0-routerid').with({
          :ensure               => 'present',
          :interface            => 'loopback0',
          :shutdown             => false,
          :description          => 'Underlay,Router ID',
          :ipv4_address         => '10.0.0.1',
          :ipv4_netmask_length  => 32,
          :ipv4_pim_sparse_mode => true,
        })
      end
      it 'creates loopback1' do
        is_expected.to contain_cisco_interface('loopback1').with({
          :ensure               => 'present',
          :interface            => 'loopback1',
          :shutdown             => false,
          :description          => 'VTEP source interface',
          :ipv4_address         => '10.0.0.101',
          :ipv4_netmask_length  => 32,
          :ipv4_address_secondary => '10.0.0.151',
          :ipv4_netmask_length_secondary => 32,
          :ipv4_pim_sparse_mode => true,
        })
      end
      it 'creates ospf & enables on lo0+lo1' do
        is_expected.to contain_cisco_ospf('UNDERLAY').with({
          :ensure => 'present'
        })
        is_expected.to contain_cisco_ospf_vrf('UNDERLAY default').with({
          :ensure => 'present',
          :router_id => '10.0.0.1',
          :bfd => true,
          :log_adjacency => 'log',
        }).that_requires('Cisco_ospf[UNDERLAY]')
        is_expected.to contain_cisco_ospf_area('UNDERLAY default 0.0.0.123').with({
          :ensure => 'present',
          :authentication => 'md5',
          :nssa => true,
        }).that_requires('Cisco_ospf_vrf[UNDERLAY default]')
        is_expected.to contain_cisco_interface_ospf('loopback0 UNDERLAY').with({
          :ensure => 'present',
          :interface => 'loopback0',
          :ospf => 'UNDERLAY',
          :area => '0.0.0.123',
        }).that_requires('Cisco_ospf_vrf[UNDERLAY default]')
        is_expected.to contain_cisco_interface_ospf('loopback1 UNDERLAY').with({
          :ensure => 'present',
          :interface => 'loopback1',
          :ospf => 'UNDERLAY',
          :area => '0.0.0.123',
        }).that_requires('Cisco_ospf_vrf[UNDERLAY default]')
      end
      it 'interfaces' do
        is_expected.to contain_cisco_interface('ethernet1/1').with({
          :ensure => 'present',
          :switchport_mode => 'disabled',
          :interface => 'ethernet1/1',
          :shutdown => false,
          :description => 'ptp_interface_1',
          :mtu => 9216,
          :ipv4_address => '10.1.0.0',
          :ipv4_netmask_length => 31,
          :ipv4_redirects => false,
          :ipv4_pim_sparse_mode => true,
          :pim_bfd => true
        })
        is_expected.to contain_cisco_interface('ethernet1/2').with({
          :ensure => 'present',
          :switchport_mode => 'disabled',
          :interface => 'ethernet1/2',
          :shutdown => false,
          :description => 'ptp_interface_2',
          :mtu => 1500,
          :ipv4_address => '10.1.0.2',
          :ipv4_netmask_length => 31,
          :ipv4_redirects => false,
          :ipv4_pim_sparse_mode => true,
          :pim_bfd => true
        })
      end
      it 'ospf interfaces' do
        is_expected.to contain_cisco_interface_ospf('ethernet1/1 UNDERLAY').with({
          :ensure                         => 'present',
          :interface                      => 'ethernet1/1',
          :ospf                           => 'UNDERLAY',
          :area                           => '0.0.0.123',
          :bfd                            => true,
          :hello_interval                 => 3,
          :network_type                   => 'p2p',
          :message_digest                 => true,
          :message_digest_key_id          => 1,
          :message_digest_algorithm_type  => 'md5',
          :message_digest_encryption_type => '3des',
          :message_digest_password        => 'e3b5189d66d7ed80',
        })
        is_expected.to contain_cisco_interface_ospf('ethernet1/2 UNDERLAY').with({
          :ensure                         => 'present',
          :interface                      => 'ethernet1/2',
          :ospf                           => 'UNDERLAY',
          :area                           => '0.0.0.123',
          :bfd                            => true,
          :hello_interval                 => 3,
          :network_type                   => 'p2p',
          :message_digest                 => true,
          :message_digest_key_id          => 1,
          :message_digest_algorithm_type  => 'md5',
          :message_digest_encryption_type => '3des',
          :message_digest_password        => 'e3b5189d66d7ed80',
        })
        is_expected.to contain_cisco_interface_ospf('Vlan2 UNDERLAY').with({
          :ensure                         => 'present',
          :interface                      => 'Vlan2',
          :ospf                           => 'UNDERLAY',
          :area                           => '0.0.0.123',
          :bfd                            => true,
          :message_digest                 => true,
          :message_digest_key_id          => 1,
          :message_digest_algorithm_type  => 'md5',
          :message_digest_encryption_type => '3des',
          :message_digest_password        => 'e3b5189d66d7ed80',
        })
      end
      it 'route maps' do
        is_expected.to contain_cisco_route_map('rm_vxlan_multicast_bum_groups 10 permit').with({
          :ensure                         => 'present',
          :match_ipv4_multicast_enable     => true,
          :match_ipv4_multicast_group_addr => '239.96.0.0/24',
        })
        is_expected.to contain_cisco_route_map('rm_multicast_enterprise 10 permit').with({
          :ensure                         => 'present',
          :match_ipv4_multicast_enable     => true,
          :match_ipv4_multicast_group_addr => '224.0.0.0/4',
        })
        is_expected.to contain_cisco_route_map('rm_multicast_local_clusters 10 permit').with({
          :ensure                         => 'present',
          :match_ipv4_multicast_enable     => true,
          :match_ipv4_multicast_group_addr => '239.255.248.0/22',
        })
      end
      it 'pim' do
        is_expected.to contain_cisco_command_config('vxlan_pim_rp').with({
          :command => "ip pim rp-address 10.255.0.1 route-map rm_vxlan_multicast_bum_groups\n"
        })
        is_expected.to contain_cisco_command_config('enterprise_pim_rp').with({
          :command => "ip pim rp-address 10.255.255.1 route-map rm_multicast_enterprise\n",
        })
        is_expected.to contain_cisco_command_config('local_pim_rp').with({
          :command => "ip pim rp-address 10.0.0.1 route-map rm_multicast_local_clusters\n",
        })
        is_expected.to contain_cisco_pim('ipv4 default').with({
          :ensure    => 'present',
          :ssm_range => '232.0.0.0/8',
        })
        is_expected.to contain_cisco_command_config('pim-misc').with({
          :command => "ip pim pre-build-spt\n"
        })
      end
      it 'underlay ptp vlan' do
        is_expected.to contain_cisco_vlan('2').with({
          :ensure    => 'present',
          :vlan_name => 'PTP,UNDERLAY,PEER-GW',
          :state     => 'active',
          :shutdown  => false,
        })
        is_expected.to contain_cisco_interface('Vlan2').with({
          :ensure               => 'present',
          :interface            => 'Vlan2',
          :shutdown             => false,
          :description          => 'underlay_vlan',
          :mtu                  => 9216,
          :ipv4_address         => '10.2.0.0',
          :ipv4_netmask_length  => 31,
          :ipv4_redirects       => false,
          :ipv4_pim_sparse_mode => true,
          :pim_bfd              => true,
          :bfd_echo             => false,
        })
      end
    end
    context 'with sane params for a border leaf switch' do
      let(:params) {{
        :loopback0_ip => '10.0.0.1',
        :loopback1_ip => '10.0.0.101',
        :ospf_area    => '0.0.0.123',
        :ptp_interfaces => {
          'ethernet1/1' => {
            'ipaddress' => '10.1.0.0',
            'description' => 'ptp_interface_1'
          },
          'ethernet1/2' => {
            'ipaddress' => '10.1.0.2',
            'description' => 'ptp_interface_2',
            'mtu' => 1500,
          }
        },
        :multicast_group_range => '239.96.0.0/24',
        :pim_anycast_rp => '10.255.0.1',
        :enterprise_pim_rp => '10.255.255.1',
      }}

      it { is_expected.to have_resource_count(19) }

      it 'creates loopback0' do
        is_expected.to contain_cisco_interface('lo0-routerid').with({
          :ensure               => 'present',
          :interface            => 'loopback0',
          :shutdown             => false,
          :description          => 'Underlay,Router ID',
          :ipv4_address         => '10.0.0.1',
          :ipv4_netmask_length  => 32,
          :ipv4_pim_sparse_mode => true,
        })
      end
      it 'creates loopback1' do
        is_expected.to contain_cisco_interface('loopback1').with({
          :ensure               => 'present',
          :interface            => 'loopback1',
          :shutdown             => false,
          :description          => 'VTEP source interface',
          :ipv4_address         => '10.0.0.101',
          :ipv4_netmask_length  => 32,
          :ipv4_pim_sparse_mode => true,
        })
      end
      it 'creates ospf & enables on lo0+lo1' do
        is_expected.to contain_cisco_ospf('UNDERLAY').with({
          :ensure => 'present'
        })
        is_expected.to contain_cisco_ospf_vrf('UNDERLAY default').with({
          :ensure => 'present',
          :router_id => '10.0.0.1',
          :bfd => true,
          :log_adjacency => 'log',
        }).that_requires('Cisco_ospf[UNDERLAY]')
        is_expected.to contain_cisco_ospf_area('UNDERLAY default 0.0.0.123').with({
          :ensure => 'present',
          :authentication => 'md5',
          :nssa => true,
        }).that_requires('Cisco_ospf_vrf[UNDERLAY default]')
        is_expected.to contain_cisco_interface_ospf('loopback0 UNDERLAY').with({
          :ensure => 'present',
          :interface => 'loopback0',
          :ospf => 'UNDERLAY',
          :area => '0.0.0.123',
        }).that_requires('Cisco_ospf_vrf[UNDERLAY default]')
        is_expected.to contain_cisco_interface_ospf('loopback1 UNDERLAY').with({
          :ensure => 'present',
          :interface => 'loopback1',
          :ospf => 'UNDERLAY',
          :area => '0.0.0.123',
        }).that_requires('Cisco_ospf_vrf[UNDERLAY default]')
      end
      it 'interfaces' do
        is_expected.to contain_cisco_interface('ethernet1/1').with({
          :ensure => 'present',
          :switchport_mode => 'disabled',
          :interface => 'ethernet1/1',
          :shutdown => false,
          :description => 'ptp_interface_1',
          :mtu => 9216,
          :ipv4_address => '10.1.0.0',
          :ipv4_netmask_length => 31,
          :ipv4_redirects => false,
          :ipv4_pim_sparse_mode => true,
          :pim_bfd => true
        })
        is_expected.to contain_cisco_interface('ethernet1/2').with({
          :ensure => 'present',
          :switchport_mode => 'disabled',
          :interface => 'ethernet1/2',
          :shutdown => false,
          :description => 'ptp_interface_2',
          :mtu => 1500,
          :ipv4_address => '10.1.0.2',
          :ipv4_netmask_length => 31,
          :ipv4_redirects => false,
          :ipv4_pim_sparse_mode => true,
          :pim_bfd => true
        })
      end
      it 'ospf interfaces' do
        is_expected.to contain_cisco_interface_ospf('ethernet1/1 UNDERLAY').with({
          :ensure                         => 'present',
          :interface                      => 'ethernet1/1',
          :ospf                           => 'UNDERLAY',
          :area                           => '0.0.0.123',
          :bfd                            => true,
          :hello_interval                 => 3,
          :network_type                   => 'p2p',
          :message_digest                 => true,
          :message_digest_key_id          => 1,
          :message_digest_algorithm_type  => 'md5',
          :message_digest_encryption_type => '3des',
          :message_digest_password        => 'e3b5189d66d7ed80',
        })
        is_expected.to contain_cisco_interface_ospf('ethernet1/2 UNDERLAY').with({
          :ensure                         => 'present',
          :interface                      => 'ethernet1/2',
          :ospf                           => 'UNDERLAY',
          :area                           => '0.0.0.123',
          :bfd                            => true,
          :hello_interval                 => 3,
          :network_type                   => 'p2p',
          :message_digest                 => true,
          :message_digest_key_id          => 1,
          :message_digest_algorithm_type  => 'md5',
          :message_digest_encryption_type => '3des',
          :message_digest_password        => 'e3b5189d66d7ed80',
        })
      end
      it 'route maps' do
        is_expected.to contain_cisco_route_map('rm_vxlan_multicast_bum_groups 10 permit').with({
          :ensure                         => 'present',
          :match_ipv4_multicast_enable     => true,
          :match_ipv4_multicast_group_addr => '239.96.0.0/24',
        })
        is_expected.to contain_cisco_route_map('rm_multicast_enterprise 10 permit').with({
          :ensure                         => 'present',
          :match_ipv4_multicast_enable     => true,
          :match_ipv4_multicast_group_addr => '224.0.0.0/4',
        })
        is_expected.to contain_cisco_route_map('rm_multicast_local_clusters 10 permit').with({
          :ensure                         => 'present',
          :match_ipv4_multicast_enable     => true,
          :match_ipv4_multicast_group_addr => '239.255.248.0/22',
        })
      end
      it 'pim' do
        is_expected.to contain_cisco_command_config('vxlan_pim_rp').with({
          :command => "ip pim rp-address 10.255.0.1 route-map rm_vxlan_multicast_bum_groups"
        })
        is_expected.to contain_cisco_command_config('enterprise_pim_rp').with({
          :command => "ip pim rp-address 10.255.255.1 route-map rm_multicast_enterprise",
        })
        is_expected.to contain_cisco_command_config('local_pim_rp').with({
          :command => "ip pim rp-address 10.0.0.1 route-map rm_multicast_local_clusters",
        })
        is_expected.to contain_cisco_pim('ipv4 default').with({
          :ensure    => 'present',
          :ssm_range => '232.0.0.0/8',
        })
        is_expected.to contain_cisco_command_config('pim-misc').with({
          :command => "ip pim pre-build-spt"
        })
      end
    end
  end
end
