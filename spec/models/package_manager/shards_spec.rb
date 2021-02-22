# frozen_string_literal: true
require 'rails_helper'

describe PackageManager::Shards do
  it 'has formatted name of "Shards"' do
    expect(described_class.formatted_name).to eq('Shards')
  end

  describe '#package_link' do
    let(:project) { create(:project, name: 'foo', platform: described_class.formatted_name) }

    it 'returns a link to project website' do
      expect(described_class.package_link(project)).to eq("https://crystal-shards-registry.herokuapp.com/shards/foo")
    end

    it 'ignores version' do
      expect(described_class.package_link(project, '2.0.0')).to eq("https://crystal-shards-registry.herokuapp.com/shards/foo")
    end
  end
end
