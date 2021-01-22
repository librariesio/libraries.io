require 'rails_helper'

describe RepositoryUpdateOrgWorker do
  it "should use the low priority queue" do
    is_expected.to be_processed_in :low
  end

  it "should sync an org" do
    org = create(:repository_organisation)
    host_type = 'GitHub'
    expect(RepositoryOrganisation).to receive(:login).with(org.login).and_return([org])
    expect(org).to receive(:sync)
    subject.perform(host_type, org.login)
  end
end
