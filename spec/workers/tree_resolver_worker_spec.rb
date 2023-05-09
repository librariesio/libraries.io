# frozen_string_literal: true

require "rails_helper"

describe TreeResolverWorker do
  it "should use the default priority queue" do
    is_expected.to be_processed_in :tree
  end

  it "should load dependencies tree for version" do
    version = create(:version)
    kind = "runtime"
    date = nil
    expect(Version).to receive(:find_by_id).with(version.id).and_return(version)
    expect(version).to receive(:load_dependencies_tree).with(kind, date)
    subject.perform(version.id, kind, date)
  end
end
