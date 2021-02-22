# frozen_string_literal: true
require 'rails_helper'

describe PackageManager::PlatformIO do
  let(:project) { create(:project, name: 'foo', platform: 'PlatformIO', pm_id: 1) }

  it 'has formatted name of "PlatformIO"' do
    expect(PackageManager::PlatformIO.formatted_name).to eq('PlatformIO')
  end

  describe '#package_link' do
    it 'returns a link to project website' do
      expect(PackageManager::PlatformIO.package_link(project)).to eq('https://platformio.org/lib/show/1/foo')
    end

    it 'ignores version' do
      expect(PackageManager::PlatformIO.package_link(project, '2.0.0')).to eq('https://platformio.org/lib/show/1/foo')
    end
  end

  describe '#install_instructions' do
    it 'returns a command to install the project' do
      expect(described_class.install_instructions(project)).to eq("platformio lib install 1")
    end

    it 'ignores version' do
      expect(described_class.install_instructions(project, '2.0.0')).to eq("platformio lib install 1")
    end
  end
end
