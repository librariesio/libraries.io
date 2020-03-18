# frozen_string_literal: true

require "rails_helper"

describe MinimumProjectSerializer do
  subject { described_class.new(build(:project)) }

  it "should have expected attribute names" do
    expect(subject.attributes.keys).to eql(%i[
      name platform
    ])
  end
end
