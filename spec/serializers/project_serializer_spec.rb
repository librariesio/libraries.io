# frozen_string_literal: true
require 'rails_helper'

describe ProjectSerializer do

  let (:default_attribute_names) { %i[
      dependent_repos_count
      dependents_count
      deprecation_reason
      description
      forks
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
      repository_url
      stars
      status
    ]
  }

  context "without updated_at" do
    subject { described_class.new(build(:project)) }

    it 'should have expected attribute names' do
      expect(subject.attributes.keys).to eq(default_attribute_names)
    end
  end

  context "with updated_at" do
    subject { described_class.new(build(:project), show_updated_at: true) }

    it 'should have expected attribute names' do
      expect(subject.attributes.keys).to eq(default_attribute_names + %i[updated_at])
    end
  end
end
