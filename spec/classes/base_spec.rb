require 'spec_helper'
describe 'cisco_datacentre::base', :type => :class do
  let(:node) { 'nexus_switch.example.com'}
  describe 'when called with no parameters on Cisco N9K switches' do
    let(:facts) {{
       :osfamily => 'RedHat',
       :operatingsystem => 'nexus'
    }}

    it { is_expected.to contain_class('cisco_datacentre::base') }

    context 'with default values for all parameters' do
      it 'set the root user password' do
        is_expected.to contain_user('root').with({
          :ensure => 'present',
          :password => 'Password123!'
        })
      end
    end
  end
end
