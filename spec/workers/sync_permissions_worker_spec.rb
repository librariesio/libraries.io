require 'rails_helper'

describe SyncPermissionsWorker do
  it "should use the user priority queue" do
    is_expected.to be_processed_in :user
  end
end
