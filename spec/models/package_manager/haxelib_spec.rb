require 'rails_helper'

describe PackageManager::Haxelib, :vcr do
  it 'has formatted name of "Haxelib"' do
    expect(described_class.formatted_name).to eq('Haxelib')
  end

  describe '#package_link' do
    let(:project) { create(:project, name: 'foo', platform: described_class.name) }

    it 'returns a link to project website' do
      expect(described_class.package_link(project)).to eq("https://lib.haxe.org/p/foo/")
    end

    it 'handles version' do
      expect(described_class.package_link(project, '2.0.0')).to eq("https://lib.haxe.org/p/foo/2.0.0")
    end
  end

  describe 'download_url' do
    it 'returns a link to project tarball' do
      expect(described_class.download_url('foo', '1.0.0')).to eq("https://lib.haxe.org/p/foo/1.0.0/download/")
    end
  end
end
