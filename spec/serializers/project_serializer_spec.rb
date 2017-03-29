require 'rails_helper'

describe ProjectSerializer do
  subject { described_class.new(build(:project)) }

  it 'should have expected attribute names' do
    expect(subject.attributes.keys).to eql([
      :name, :platform, :description, :language, :homepage,
      :repository_url, :normalized_licenses, :rank, :status,
      :latest_release_number, :latest_release_published_at,
      :package_manager_url, :stars, :forks, :keywords,
      :latest_stable_release
    ])
  end
end
