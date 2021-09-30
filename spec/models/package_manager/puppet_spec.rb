# frozen_string_literal: true
require 'rails_helper'

describe PackageManager::Puppet do
  let(:project) { create(:project, name: 'foo-bar', platform: described_class.formatted_name) }

  it 'has formatted name of "Puppet"' do
    expect(described_class.formatted_name).to eq('Puppet')
  end

  describe '#package_link' do
    it 'returns a link to project website' do
      expect(described_class.package_link(project)).to eq("https://forge.puppet.com/foo/bar")
    end

    it 'handles version' do
      expect(described_class.package_link(project, '2.0.0')).to eq("https://forge.puppet.com/foo/bar/2.0.0")
    end
  end

  describe 'download_url' do
    it 'returns a link to project tarball' do
      expect(described_class.download_url(project, '1.0.0')).to eq("https://forge.puppet.com/v3/files/foo-bar-1.0.0.tar.gz")
    end
  end

  describe '#install_instructions' do
    it 'returns a command to install the project' do
      expect(described_class.install_instructions(project)).to eq("puppet module install foo-bar")
    end

    it 'handles version' do
      expect(described_class.install_instructions(project, '2.0.0')).to eq("puppet module install foo-bar --version 2.0.0")
    end
  end
end
