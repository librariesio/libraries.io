# frozen_string_literal: true

require "rails_helper"

describe RepositoryUpdatedSerializer do
  subject { described_class.new(build(:repository)) }

  it "should have expected attribute names" do
    expect(subject.attributes.keys).to eql(%i[
    full_name
    host_type
    name
    updated_at
    url
  ])
  end
end
