require 'spec_helper'
describe 'rbc_cisco_datacentre::evpn::layer2vlan', :type => :define do
  let(:title) { '123' }
  let(:params) {{
    :vlan_id          => 123,
    :vlan_name        => 'test123',
  }}

  it { is_expected.to compile }
  it { is_expected.to have_resource_count(2) }

  it 'when declared' do
    is_expected.to contain_cisco_vlan('123').with({
      :ensure => 'present',
      :vlan_name => 'test123',
      :state      => 'active',
      :shutdown   => false,
    })
  end
end
