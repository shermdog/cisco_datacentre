require 'spec_helper'
describe 'cisco_datacentre::evpn::spineglobal', :type => :class do
  let(:node) { 'nexus_switch.example.com' }
  describe 'When declared' do
    let(:facts) {{
      :osfamily        => 'RedHat',
      :operatingsystem => 'nexus'
    }}

    it { is_expected.to compile }
    it { is_expected.to contain_class('cisco_datacentre::evpn::spineglobal') }
    it { is_expected.to have_resource_count(1) }

    context 'includes settings for' do
      it 'bfd' do
        is_expected.to contain_cisco_bfd_global('default').with({
          :ensure        => 'present',
          :ipv4_interval => [ 150, 150, 3 ],
          :startup_timer => 0
        })
      end
    end
  end
end
