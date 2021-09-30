# frozen_string_literal: true
require 'rails_helper'

describe PackageManager::Hackage do
  let(:project) { create(:project, name: 'foo', platform: described_class.formatted_name) }

  it 'has formatted name of "Hackage"' do
    expect(described_class.formatted_name).to eq('Hackage')
  end

  describe '#package_link' do
    it 'returns a link to project website' do
      expect(described_class.package_link(project)).to eq("http://hackage.haskell.org/package/foo")
    end

    it 'handles version' do
      expect(described_class.package_link(project, '2.0.0')).to eq("http://hackage.haskell.org/package/foo-2.0.0")
    end
  end

  describe 'download_url' do
    it 'returns a link to project tarball' do
      expect(described_class.download_url(project, '1.0.0')).to eq("http://hackage.haskell.org/package/foo-1.0.0/foo-1.0.0.tar.gz")
    end
  end

  describe '#install_instructions' do
    it 'returns a command to install the project' do
      expect(described_class.install_instructions(project)).to eq("cabal install foo")
    end

    it 'handles version' do
      expect(described_class.install_instructions(project, '2.0.0')).to eq("cabal install foo-2.0.0")
    end
  end
end
