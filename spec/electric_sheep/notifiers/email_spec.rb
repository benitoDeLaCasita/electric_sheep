require 'spec_helper'

describe ElectricSheep::Notifiers::Email do
  include Support::Options

  before do
    Mail::TestMailer.deliveries.clear
  end

  let(:resource) do
    ElectricSheep::Resources::File.new(path: 'path/to/file').tap do |resource|
      resource.stat! 1024
    end
  end

  let(:project){
    ElectricSheep::Metadata::Project.new(id: 'some-project').tap do |p|
      p.stubs(:report).returns(mock(stack: []))
      p.stubs(:last_product).returns(resource)
    end
  }

  let(:metadata){
    ElectricSheep::Metadata::Notifier.new(
      agent: 'email',
      from: 'from@host.tld',
      to: 'to@host.tld',
      using: :test,
      with: {}
    )
  }
  let(:logger){ mock }
  let(:hosts){ ElectricSheep::Metadata::Hosts.new }

  let(:notifier) do
    subject.new(
      project,
      hosts,
      logger,
      metadata
    )
  end

  it{
    defines_options :from, :to, :using, :with
    # TODO requires :from, :to, :using
  }

  it 'should have registered as the "email" notifier' do
    ElectricSheep::Agents::Register.notifier("email").must_equal subject
  end

  {
    success: 'Backup successful: some-project',
    failed: 'BACKUP FAILED: some-project'
  }.each do |status, subject|
    it "delivers the notification for a project with status #{status}" do
      project.instance_variable_set(:@status, status)
      notifier.notify!
      Mail::TestMailer.deliveries.length.must_equal 1
      Mail::TestMailer.deliveries.first.tap do |delivery|
        delivery.from.must_equal [metadata.from]
        delivery.to.must_equal [metadata.to]
        delivery.subject.must_equal subject
        # Could we ensure preflight has been done without this kind of hack ?
        delivery.html_part.body.to_s.wont_match /\.headerContent/
      end
    end
  end


end