# frozen_string_literal: true

require "rails_helper"

describe PackageManager::Pypi::RssApiReleases do
  describe ".request" do
    let(:project_name) { "project" }
    let(:rss_url) { "rss_url" }
    let(:xml_data) { Ox.parse(raw_data) }
    let(:raw_data) do
      <<~XML
        <?xml version="1.0" ?>
        <rss>
          <channel>
            <whatever />
          </channel>
        </rss>
      XML
    end

    before do
      allow(described_class).to receive(:request_url).with(project_name: project_name).and_return(rss_url)
      allow(PackageManager::ApiService).to receive(:request_and_parse_xml).with(rss_url).and_return(xml_data)
    end

    context "with missing rss/channel node" do
      let(:raw_data) do
        <<~XML
          <?xml version="1.0" ?>
          <rss>
            <whatever />
          </rss>
        XML
      end

      it "raises error" do
        expect { described_class.request(project_name: project_name) }.to raise_error(described_class::InvalidReleasesFeedStructure)
      end
    end

    context "with rss/channel node" do
      it "produces a new object" do
        expect(described_class.request(project_name: project_name)).to be_a(described_class)
      end
    end
  end

  describe "#releases" do
    let(:rss_api_releases) { described_class.new(xml_data: xml_data) }
    let(:xml_data) { Ox.parse(raw_data) }
    let(:raw_data) do
      <<~XML
        <?xml version="1.0" ?>
        <rss>
          <channel>
            <item>
              <title>#{version_number}</title>
              <pubDate>#{published_at.rfc2822}</pubDate>
            </item>
          </channel>
        </rss>
      XML
    end

    let(:version_number) { "1.0.0" }
    let(:published_at) { Time.now }

    context "malformed feed item" do
      let(:raw_data) do
        <<~XML
          <?xml version="1.0" ?>
          <rss>
            <channel>
              <item>
                <title>#{version_number}</title>
              </item>
            </channel>
          </rss>
        XML
      end

      it "raises an exception" do
        expect { rss_api_releases.releases }.to raise_error(described_class::InvalidReleasesFeedStructure)
      end
    end

    context "correct feed item" do
      it "generates the correct releases" do
        results = rss_api_releases.releases

        expect(results.length).to eq(1)
        expect(results.first.version_number).to eq(version_number)
        # deal with microtime
        expect(results.first.published_at).to be_within(1.second).of(published_at)
      end
    end
  end
end
