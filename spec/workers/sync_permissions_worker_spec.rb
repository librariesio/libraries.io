# frozen_string_literal: true

require "rails_helper"

describe SyncPermissionsWorker do
  it "should use the user priority queue" do
    is_expected.to be_processed_in :user
  end

  it "should call to sync user permissions" do
    user = create(:user)
    allow(User).to receive(:find_by_id).with(user.id).and_return(user)
    allow(user).to receive(:update_repo_permissions)
    subject.perform(user.id)
    expect(user).to have_received(:update_repo_permissions)
  end

  context "with recorded data" do
    before do
      freeze_time
    end

    it "should sync user permissions and repositories" do
      VCR.use_cassette("github/user_sync") do
        user = create(:user)
        user.identities.update_all(token: "TEST_TOKEN")

        expect(user.repository_permissions.count).to be 0
        expect(Repository.count).to be 0
        expect(RepositoryDownloadWorker.jobs.size).to be 0

        expect(User).to receive(:find_by_id).with(user.id).and_return(user)
        subject.perform(user.id)

        # expect permissions were added
        expect(user.repository_permissions.count).to be 83
        # expect repositories for those permissions to have been added
        expect(Repository.count).to be 83
        # expect work to be queued up to sync data for those repositories
        expect(RepositoryDownloadWorker.jobs.size).to be 166
        # make sure we set a sync date
        expect(user.last_synced_at).to eql(Time.current)
      end
    end
  end
end
