# frozen_string_literal: true

require "rails_helper"

describe PlatformSerializer do
  subject { described_class.new(build(:platform)) }

  it "should have expected attribute names" do
    expect(subject.attributes.keys).to eql(%i[
      name project_count homepage color default_language
    ])
  end
end
