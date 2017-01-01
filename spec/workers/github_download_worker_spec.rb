require 'rails_helper'

describe GithubDownloadWorker do
  it "should use the low priority queue" do
    is_expected.to be_processed_in :low
  end
end
