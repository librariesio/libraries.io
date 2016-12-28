require 'rails_helper'

describe PackageManager::Hex, :vcr do
  it 'has formatted name of "Hex"' do
    expect(described_class.formatted_name).to eq('Hex')
  end

  describe '#package_link' do
    let(:project) { create(:project, name: 'foo', platform: described_class.name) }

    it 'returns a link to project website' do
      expect(described_class.package_link(project)).to eq("https://hex.pm/packages/foo/")
    end

    it 'handles version' do
      expect(described_class.package_link(project, '2.0.0')).to eq("https://hex.pm/packages/foo/2.0.0")
    end
  end

  describe 'download_url' do
    it 'returns a link to project tarball' do
      expect(described_class.download_url('foo', '1.0.0')).to eq("https://repo.hex.pm/tarballs/foo-1.0.0.tar")
    end
  end
end
