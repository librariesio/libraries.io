# frozen_string_literal: true

require "rails_helper"

describe Version, type: :model do
  it { should belong_to(:project) }
  it { should have_many(:dependencies) }
  it { should have_many(:runtime_dependencies).conditions(kind: %w[runtime normal]) }

  it { should validate_presence_of(:project_id) }
  it { should validate_presence_of(:number) }

  context "spdx expressions" do
    let(:project) { create(:project) }
    it "updates spdx expressions on save" do
      version = Version.create(project: project, original_license: "MIT", number: "1.0.0")
      version.save
      expect(version.spdx_expression).to eq "MIT"
    end

    it "sets spdx expression to NONE when there is no license set" do
      version = Version.create(project: project, original_license: "", number: "1.0.0")
      version.save
      expect(version.spdx_expression).to eq "NONE"
    end

    it "sets spdx expression to NOASSERTION when the license is something we don't understand" do
      version = Version.create(project: project, original_license: "some fake license", number: "1.0.0")
      version.save
      expect(version.spdx_expression).to eq "NOASSERTION"
    end
  end

  context "version_mailing_list" do
    let(:repository) { create(:repository) }
    let(:project) { create(:project, repository: repository) }
    let(:version) { create(:version, project: project) }

    def create_sub(user)
      Subscription.create(project: project, user: user)
    end

    def create_repo_sub(user)
      repo_sub = RepositorySubscription.create(user: user, repository: repository)
      Subscription.create(project: project, repository_subscription: repo_sub)
    end

    it "builds a version mailing list for notifications" do
      create_sub(create(:user))
      create_repo_sub(create(:user))
      expect(version.mailing_list.count).to eq 2
    end

    it "doesn't email users with disabled emails" do
      create_sub(create(:user))
      create_sub(create(:user, emails_enabled: false))

      expect(version.mailing_list.count).to eq 1
    end

    it "doesn't email users who muted project" do
      mute_user = create(:user)
      create_sub(mute_user)
      create_sub(create(:user))
      ProjectMute.create(project: project, user: mute_user)

      expect(version.mailing_list.count).to eq 1
    end
  end
end
