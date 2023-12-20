# frozen_string_literal: true

require "rails_helper"

describe ProactiveProjectSyncWorker do
  it "should use the ___ priority queue" do
    is_expected.to be_processed_in :small
  end

  it "targets only watched projects"
  it "targets only projects from selected platforms"
end
