# frozen_string_literal: true
require 'rails_helper'

describe PackageManager::Clojars do
  it 'has formatted name of "Clojars"' do
    expect(described_class.formatted_name).to eq('Clojars')
  end

  describe '#package_link' do
    let(:project) { create(:project, name: 'foo', platform: described_class.formatted_name) }

    it 'returns a link to project website' do
      expect(described_class.package_link(project)).to eq("https://clojars.org/foo")
    end

    it 'handles version' do
      expect(described_class.package_link(project, '2.0.0')).to eq("https://clojars.org/foo/versions/2.0.0")
    end
  end
end
