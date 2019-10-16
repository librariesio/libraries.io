require 'rails_helper'

describe ProjectSerializer do
  subject { described_class.new(build(:project)) }

  it 'should have expected attribute names' do
    expect(subject.attributes.keys).to eq(
      %i[
        dependent_repos_count
        dependents_count
        description
        forks
        homepage
        keywords
        language
        latest_download_url
        latest_release_number
        latest_release_published_at
        latest_stable_release
        latest_stable_release_number
        latest_stable_release_published_at
        license_normalized
        licenses
        name
        normalized_licenses
        package_manager_url
        platform
        rank
        repository_url
        stars
        status
      ]
    )
  end
end
