require 'rails_helper'

describe PackageManager::Cargo, :vcr do
  it 'has formatted name of "Cargo"' do
    expect(described_class.formatted_name).to eq('Cargo')
  end

  describe '#package_link' do
    let(:project) { create(:project, name: 'foo', platform: described_class.name) }

    it 'returns a link to project website' do
      expect(described_class.package_link(project)).to eq("https://crates.io/crates/foo/")
    end

    it 'handles version' do
      expect(described_class.package_link(project, '2.0.0')).to eq("https://crates.io/crates/foo/2.0.0")
    end
  end

  describe 'download_url' do
    it 'returns a link to project tarball' do
      expect(described_class.download_url('foo', '1.0.0')).to eq("https://crates.io/api/v1/crates/foo/1.0.0/download")
    end
  end
end
