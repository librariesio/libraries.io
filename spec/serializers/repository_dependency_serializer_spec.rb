# frozen_string_literal: true

require "rails_helper"

describe RepositoryDependencySerializer do
  subject { described_class.new(build(:repository_dependency)) }

  it "should have expected attribute names" do
    expect(subject.attributes.keys).to eql(%i[
      project_name name platform requirements latest_stable
      latest deprecated outdated filepath kind
    ])
  end
end
