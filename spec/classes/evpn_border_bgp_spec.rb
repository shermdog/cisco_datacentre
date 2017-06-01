require 'spec_helper'
describe 'cisco_datacentre::evpn::border_bgp', :type => :class do
  let(:node) { 'nexus_switch.example.com' }
  describe 'When declared' do
    let(:facts) {{
      :osfamily        => 'RedHat',
      :operatingsystem => 'nexus'
    }}
    let(:params) {{
      :loopback0_ip => '10.0.0.1',
      :bgp_asn => '65501',
      :vxlan_vrf => 'test',
      :external_bgp_neighbors => {
        '10.250.0.1' => {
          'description' => 'core1',
          'asn' => '65535',
          },
        '10.250.0.2' => {
          'description' => 'core2',
          'asn' => '65535'
        }
      },
      :advertised_networks => ['10.198.0.0/24', '10.199.0.0/24'],
    }}

    it { is_expected.to compile }
    it { is_expected.to contain_class('cisco_datacentre::evpn::border_bgp') }
    it { is_expected.to have_resource_count(9) }

    it 'bgp process' do
      is_expected.to contain_cisco_bgp('65501 test').with({
        :ensure => 'present',
        :router_id => '10.0.0.1'
      })
    end
    it 'prefix list & routemap' do
      is_expected.to contain_cisco_command_config('pl_allowed_networks_10').with({
        :command => "ip prefix-list pl_allowed_networks seq 10 permit 10.198.0.0/24\n",
      })
      is_expected.to contain_cisco_command_config('pl_allowed_networks_20').with({
        :command => "ip prefix-list pl_allowed_networks seq 20 permit 10.199.0.0/24\n",
      })
      is_expected.to contain_cisco_command_config('external_bgp_route-map').with({
        :command => "route-map rm_pod_as65501_out permit 1000\n  match ip address prefix-list pl_allowed_networks\n  set community 65501:100\n",
      })
    end
    it 'bgp neighbors & advertisements' do
      is_expected.to contain_cisco_bgp_neighbor('65501 test 10.250.0.1').with({
        :ensure        => 'present',
        :description   => 'core1',
        :bfd           => true,
        :remote_as     => '65535',
        :password      => '9125d59c18a9b015',
        :password_type => '3des',
      })
      is_expected.to contain_cisco_bgp_neighbor('65501 test 10.250.0.2').with({
        :ensure        => 'present',
        :description   => 'core2',
        :bfd           => true,
        :remote_as     => '65535',
        :password      => '9125d59c18a9b015',
        :password_type => '3des',
      })
      is_expected.to contain_cisco_bgp_neighbor_af('65501 test 10.250.0.1 ipv4 unicast').with({
        :ensure                  => 'present',
        :send_community          => 'standard',
        :soft_reconfiguration_in => 'always',
        :route_map_out           => 'rm_pod_as65501_out',
      })
      is_expected.to contain_cisco_bgp_neighbor_af('65501 test 10.250.0.2 ipv4 unicast').with({
        :ensure                  => 'present',
        :send_community          => 'standard',
        :soft_reconfiguration_in => 'always',
        :route_map_out           => 'rm_pod_as65501_out',
      })
      is_expected.to contain_cisco_bgp_af('border_network_advertisements').with({
        :ensure               => 'present',
        :asn                  => '65501',
        :vrf                  => 'test',
        :afi                  => 'ipv4',
        :safi                 => 'unicast',
        :advertise_l2vpn_evpn => true,
        :maximum_paths        => 4,
        :maximum_paths_ibgp   => 4,
        :networks             => [['10.198.0.0/24'], ['10.199.0.0/24']],
      })
    end

  end
end
