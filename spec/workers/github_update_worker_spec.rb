require 'rails_helper'

describe GithubUpdateWorker do
  it "should use the low priority queue" do
    is_expected.to be_processed_in :low
  end
end
