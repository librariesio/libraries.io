require 'rails_helper'

describe RepositoryDownloadWorker do
  it "should use the low priority queue" do
    is_expected.to be_processed_in :low
  end

  it "should update all info for a repo" do
    repo = create(:repository)
    expect(Repository).to receive(:find_by_id).with(repo.id).and_return(repo)
    expect(repo).to receive(:update_all_info)
    subject.perform(repo.id)
  end
end
