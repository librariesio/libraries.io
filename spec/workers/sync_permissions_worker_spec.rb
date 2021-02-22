# frozen_string_literal: true
require 'rails_helper'

describe SyncPermissionsWorker do
  it "should use the user priority queue" do
    is_expected.to be_processed_in :user
  end

  it "should sync user permissions" do
    user = create(:user)
    expect(User).to receive(:find_by_id).with(user.id).and_return(user)
    expect(user).to receive(:update_repo_permissions)
    subject.perform(user.id)
  end
end
