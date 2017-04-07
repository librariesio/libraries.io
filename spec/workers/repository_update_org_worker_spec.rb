require 'rails_helper'

describe RepositoryUpdateOrgWorker do
  it "should use the low priority queue" do
    is_expected.to be_processed_in :owners
  end

  it "should sync an org" do
    org = create(:repository_organisation)
    expect(RepositoryOrganisation).to receive(:find_by_login).with(org.login).and_return(org)
    expect(org).to receive(:sync)
    subject.perform(org.login)
  end
end
