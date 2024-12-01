# frozen_string_literal: true

require "rails_helper"

describe ProjectSerializer do
  let(:default_attribute_names) do
    %i[
      code_of_conduct_url
      contributions_count
      contribution_guidelines_url
      dependent_repos_count
      dependents_count
      deprecation_reason
      description
      forks
      funding_urls
      homepage
      keywords
      language
      latest_download_url
      latest_release_number
      latest_release_published_at
      latest_stable_release_number
      latest_stable_release_published_at
      license_normalized
      licenses
      name
      normalized_licenses
      package_manager_url
      platform
      rank
      repository_license
      repository_status
      repository_url
      security_policy_url
      stars
      status
    ]
  end

  context "without updated_at" do
    subject { described_class.new(build(:project)) }

    it "should have expected attribute names" do
      expect(subject.attributes.keys).to eq(default_attribute_names)
    end
  end

  context "with updated_at" do
    subject { described_class.new(build(:project), show_updated_at: true) }

    it "should have expected attribute names" do
      expect(subject.attributes.keys).to eq(default_attribute_names + %i[updated_at])
    end
  end

  context "with a project that has a repository that does not match repository_url" do
    let(:repository) { create(:repository) }
    let(:project) { create(:project, repository_url: "https://github.com/something/unused", repository: repository) }
    subject { described_class.new(project) }
    it "should return repository_url not repository.url" do
      expect(project.repository_url).not_to eq(project.repository.url)
      expect(subject.attributes[:repository_url]).to eq(project.repository_url)
    end
  end
end
