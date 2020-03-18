# frozen_string_literal: true

require "rails_helper"

describe VersionSerializer do
  subject { described_class.new(build(:version)) }

  it "should have expected attribute names" do
    expect(subject.attributes.keys).to eql(%i[number published_at])
  end
end
