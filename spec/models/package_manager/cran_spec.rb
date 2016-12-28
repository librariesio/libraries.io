require 'rails_helper'

describe PackageManager::CRAN, :vcr do
  it 'has formatted name of "CRAN"' do
    expect(described_class.formatted_name).to eq('CRAN')
  end

  describe '#package_link' do
    let(:project) { create(:project, name: 'foo', platform: described_class.name) }

    it 'returns a link to project website' do
      expect(described_class.package_link(project)).to eq("https://CRAN.R-project.org/package=foo")
    end

    it 'ignores version' do
      expect(described_class.package_link(project, '2.0.0')).to eq("https://CRAN.R-project.org/package=foo")
    end
  end

  describe 'download_url' do
    it 'returns a link to project tarball' do
      expect(described_class.download_url('foo', '1.0.0')).to eq("https://cran.r-project.org/src/contrib/foo_1.0.0.tar.gz")
    end
  end
end
