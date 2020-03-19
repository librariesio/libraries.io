require 'rails_helper'

describe VersionSerializer do
  subject { described_class.new(build(:version)) }

  it 'should have expected attribute names' do
    expect(subject.attributes.keys).to eql([:number, :published_at, :spdx_expression])
  end
end
