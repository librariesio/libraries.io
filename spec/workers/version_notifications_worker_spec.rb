require 'rails_helper'

describe VersionNotificationsWorker do
  it "should use the critical priority queue" do
    is_expected.to be_processed_in :critical
  end
end
