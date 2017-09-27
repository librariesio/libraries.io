require 'rails_helper'

describe SubscriptionSerializer do
  subject { described_class.new(build(:subscription)) }

  it 'should have expected attribute names' do
    expect(subject.attributes.keys).to eql([
      :include_prerelease, :created_at, :updated_at
    ])
  end
end
