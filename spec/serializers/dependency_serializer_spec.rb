require 'rails_helper'

describe DependencySerializer do
  subject { described_class.new(build(:dependency)) }

  it 'should have expected attribute names' do
    expect(subject.attributes.keys).to eql([:project_name, :name, :platform,
                                            :requirements, :latest_stable,
                                            :latest, :deprecated, :outdated,
                                            :filepath, :kind])
  end
end
