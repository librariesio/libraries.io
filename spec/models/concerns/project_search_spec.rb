# frozen_string_literal: true

require "rails_helper"

RSpec.describe ProjectSearch do
  subject { build(:project) }

  it "Marshals properly" do
    original = subject.to_json
    result = Marshal.load(Marshal.dump(subject)).to_json

    expect(result).to eq(original)
  end
end
