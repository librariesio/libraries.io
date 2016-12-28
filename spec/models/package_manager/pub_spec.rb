require 'rails_helper'

describe PackageManager::Pub, :vcr do
  it 'has formatted name of "Pub"' do
    expect(described_class.formatted_name).to eq('Pub')
  end

  describe '#package_link' do
    let(:project) { create(:project, name: 'foo', platform: described_class.name) }

    it 'returns a link to project website' do
      expect(described_class.package_link(project)).to eq("https://pub.dartlang.org/packages/foo")
    end

    it 'ignores version' do
      expect(described_class.package_link(project, '2.0.0')).to eq("https://pub.dartlang.org/packages/foo")
    end
  end

  describe 'download_url' do
    it 'returns a link to project tarball' do
      expect(described_class.download_url('foo', '1.0.0')).to eq("https://storage.googleapis.com/pub.dartlang.org/packages/foo-1.0.0.tar.gz")
    end
  end
end
