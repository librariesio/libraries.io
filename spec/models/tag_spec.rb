# frozen_string_literal: true

require "rails_helper"

describe Tag, type: :model do
  it { should belong_to(:repository) }

  it { should validate_presence_of(:name) }
  it { should validate_presence_of(:sha) }
  it { should validate_presence_of(:repository) }
  it { should validate_uniqueness_of(:name).scoped_to(:repository_id) }

  context "notify_subscribers" do
    let(:repository) { create(:repository) }
    let(:project) { create(:project, repository: repository) }
    let(:user) { create(:user) }
    it "notifies subscribers" do
      allow(Rails.application.config).to receive(:version_emails_enabled).and_return(true)
      Subscription.create(project: project, user: user)
      tag = Tag.create(repository: repository, name: "somename", sha: "somesha")
      allow_any_instance_of(VersionsMailer).to receive(:new_version).with(anything).and_return(true)
      expect(tag.notify_subscribers.count).to eq 1
    end

    it "sends nothing when version emails are disabled" do
      allow(Rails.application.config).to receive(:version_emails_enabled).and_return(false)
      Subscription.create(project: project, user: user)
      tag = Tag.create(repository: repository, name: "somename", sha: "somesha")
      expect(VersionsMailer).not_to receive(:new_version)
      tag.notify_subscribers
    end
  end
end
