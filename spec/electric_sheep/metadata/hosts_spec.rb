require 'spec_helper'

describe ElectricSheep::Metadata::Host do
  include Support::Options

  it{
    defines_options :hostname, :id, :description, :ssh_port, :private_key
    requires :hostname
  }

  it 'is remote' do
    subject.new.local?.must_equal false
  end

  it 'uses its id when converting to string' do
    subject.new(id: 'some-id').to_s.must_equal 'some-id'
  end

end

describe ElectricSheep::Metadata::Localhost do
  it 'is local' do
    subject.new.local?.must_equal true
  end

  it 'use "localhost" id when converting to string' do
    subject.new.to_s.must_equal 'localhost'
  end
end

describe ElectricSheep::Metadata::Hosts do

  before do
    @hosts = subject.new
  end

  it 'should add host' do
    host = @hosts.add('some-host', hostname: 'some-host.tld', description: 'Some host' )
    host.id.must_equal 'some-host'
    host.hostname.must_equal 'some-host.tld'
    host.description.must_equal 'Some host'
  end

  it 'should find host by id' do
    host = @hosts.add('some-host', hostname: 'some-host.tld', description: 'Some host' )
    @hosts.get('some-host').must_equal host
  end

  it ' raise error on finding unknown host' do
    ->{ @hosts.get('some-host')}.must_raise ElectricSheep::SheepException
  end

  it 'resolves localhost' do
    @hosts.get('localhost').must_equal @hosts.localhost
  end

  it 'returns a localhost singleton' do
    @hosts.localhost.must_be_instance_of ElectricSheep::Metadata::Localhost
    @hosts.localhost.must_be_same_as @hosts.localhost
  end

end
