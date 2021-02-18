require 'rails_helper'

describe PackageManager::Wordpress do
  it 'has formatted name of "WordPress"' do
    expect(described_class.formatted_name).to eq('WordPress')
  end

  describe '#package_link' do
    let(:project) { create(:project, name: 'foo', platform: described_class.formatted_name) }

    it 'returns a link to project website' do
      expect(described_class.package_link(project)).to eq("https://wordpress.org/plugins/foo/")
    end

    it 'handles version' do
      expect(described_class.package_link(project, '2.0.0')).to eq("https://wordpress.org/plugins/foo/2.0.0")
    end
  end

  describe '.download_url' do
    it 'returns a link to project tarball' do
      expect(described_class.download_url('foo', '1.0.0')).to eq("https://downloads.wordpress.org/plugin/foo.1.0.0.zip")
    end
  end

  describe ".versions" do
    it "returns all versions if present" do
      expect(described_class.versions({"versions" => {"1" => "uri.zip", "2" => "uri.zip"}}, "foo-package"))
        .to eq([{number: "1", published_at: nil}, {number: "2", published_at: nil}])
    end

    it "returns current version only if other versions not present" do
      expect(described_class.versions({"version" => "0.0.1", "last_updated" => "2021-02-05 11:17am GMT", "versions" => []}, "foo-package"))
        .to eq([{number: "0.0.1", published_at: "2021-02-05 11:17am GMT"}])
    end
  end
end
