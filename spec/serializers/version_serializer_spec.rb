require 'rails_helper'

describe VersionSerializer do
  subject { described_class.new(build(:version)).serializable_hash[:data][:attributes].keys }

  it 'should have expected attribute names' do
    is_expected.to eql([:number, :published_at])
  end
end
