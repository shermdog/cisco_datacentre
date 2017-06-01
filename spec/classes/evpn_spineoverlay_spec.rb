require 'spec_helper'
describe 'cisco_datacentre::evpn::spineoverlay', :type => :class do
  let(:node) { 'nexus_switch.example.com' }
  describe 'When declared with parameters' do
    let(:facts) {{
      :osfamily        => 'RedHat',
      :operatingsystem => 'nexus'
    }}
    let(:params) {{
      :bgp_asn      => '65501',
      :loopback0_ip => '10.0.0.1',
      :leaf_bgp_peers => {
        '10.1.1.1' => 'leaf1',
        '10.2.2.2' => 'leaf2'
      }
    }}

    it { is_expected.to compile }
    it { is_expected.to contain_class('cisco_datacentre::evpn::spineoverlay') }
    it { is_expected.to have_resource_count(5) }

    context 'includes settings for' do
      it 'process-level bgp' do
        is_expected.to contain_cisco_bgp('65501 default').with({
          :ensure               => 'present',
          :router_id            => '10.0.0.1',
          :log_neighbor_changes => true
        })
      end
      it 'bgp neighbors & AF' do
        is_expected.to contain_cisco_bgp_neighbor('65501 default 10.1.1.1').with({
          :ensure        => 'present',
          :description   => 'leaf1',
          :bfd           => true,
          :remote_as     => '65501',
          :update_source => 'loopback0',
          :password      => '9125d59c18a9b015',
          :password_type => '3des'
        })
        is_expected.to contain_cisco_bgp_neighbor('65501 default 10.2.2.2').with({
          :ensure        => 'present',
          :description   => 'leaf2',
          :bfd           => true,
          :remote_as     => '65501',
          :update_source => 'loopback0',
          :password      => '9125d59c18a9b015',
          :password_type => '3des'
        })
        is_expected.to contain_cisco_bgp_neighbor_af('65501 default 10.1.1.1 l2vpn evpn').with({
          :ensure                  => 'present',
          :send_community          => 'extended',
          :route_reflector_client  => true,
          :soft_reconfiguration_in => 'always'
        })
        is_expected.to contain_cisco_bgp_neighbor_af('65501 default 10.2.2.2 l2vpn evpn').with({
          :ensure                  => 'present',
          :send_community          => 'extended',
          :route_reflector_client  => true,
          :soft_reconfiguration_in => 'always'
        })
      end
    end
  end
end
