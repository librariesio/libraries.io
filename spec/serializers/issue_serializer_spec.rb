# frozen_string_literal: true

require "rails_helper"

describe IssueSerializer do
  subject { described_class.new(build(:issue)) }

  it "should have expected attribute names" do
    expect(subject.attributes.keys).to eql(%i[
      number state title body locked closed_at created_at
      updated_at uuid host_type
    ])
  end
end
