# frozen_string_literal: true

require "rails_helper"

describe VersionSerializer do
  let(:version) { build(:version) }

  def serialized(version)
    described_class.new(version).attributes
  end

  it "should have expected attribute names" do
    expect(serialized(version).keys).to eql(%i[number published_at spdx_expression original_license researched_at repository_sources])
  end

  it "should default repository_source to the project platform" do
    expect(serialized(version)[:repository_sources]).to contain_exactly("Rubygems")

    version = build(:version, repository_sources: %w[SpringLibs Maven])
    expect(serialized(version)[:repository_sources]).to contain_exactly("SpringLibs", "Maven")
  end
end
