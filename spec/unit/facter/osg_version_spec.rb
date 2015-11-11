require 'facter/osg_version'
require 'spec_helper'

describe 'osg_version fact' do
  before do
    Facter.clear
  end

  after do
    Facter.clear
  end
  
  before :each do
    Facter.fact(:osfamily).stubs(:value).returns("RedHat")
  end

  it "should return correct version 3.2.30" do
    Facter::Util::FileRead.expects(:read).with('/etc/osg-version').returns(my_fixture_read('osg-version-3.2.30'))
    Facter.fact(:osg_version).value.should == '3.2.30'
  end

  it "should return nothing if /etc/osg-version is not present" do
    Facter::Util::Resolution.any_instance.stubs(:warn)
    Facter::Util::FileRead.stubs(:read).with('/etc/osg-version').raises(Errno::ENOENT)
    Facter.fact(:osg_version).value.should == nil
  end
end
