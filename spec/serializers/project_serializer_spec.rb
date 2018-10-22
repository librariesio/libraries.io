require 'rails_helper'

describe ProjectSerializer do
  subject { described_class.new(build(:project)) }

  it 'should have expected attribute names' do
    expect(subject.attributes.keys).to eql([
      :name, :platform, :description, :homepage, :repository_url,
      :normalized_licenses, :rank, :latest_release_published_at,
      :latest_release_number, :language, :status, :package_manager_url,
      :stars, :forks, :keywords, :latest_stable_release, :latest_download_url,
      :dependents_count, :dependent_repos_count,
      :latest_stable_release_number, :latest_stable_release_published_at
    ])
  end
end
