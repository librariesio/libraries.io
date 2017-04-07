require 'rails_helper'

describe RepositoryUpdateUserWorker do
  it "should use the low priority queue" do
    is_expected.to be_processed_in :owners
  end

  it "should sync an user" do
    user = create(:repository_user)
    expect(RepositoryUser).to receive(:find_by_login).with(user.login).and_return(user)
    expect(user).to receive(:sync)
    subject.perform(user.login)
  end
end
