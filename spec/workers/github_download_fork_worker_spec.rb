require 'rails_helper'

describe GithubDownloadForkWorker, :vcr do
  it "should use the low priority queue" do
    is_expected.to be_processed_in :low
  end

  it "should download a repos forks" do
    repo = create(:github_repository)
    expect(GithubRepository).to receive(:find_by_id).with(repo.id).and_return(repo)
    expect(repo).to receive(:download_forks)
    subject.perform(repo.id)
  end
end
