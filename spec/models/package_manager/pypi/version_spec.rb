require "rails_helper"

describe PackageManager::Pypi::Version do
  describe ".retrieve_project_releases_rss_feed" do
    let(:name) { "name" }

    before do
      allow(described_class).to receive(:get_xml).with("https://pypi.org/rss/project/#{name}/releases.xml").and_return(result)
    end

    context "with invalid rss feed" do
      let(:result) { Ox.parse("<bad></bad>") }

      it "raises an exception" do
        expect { described_class.retrieve_project_releases_rss_feed(name: name) }.to raise_error(described_class::InvalidReleasesFeedStructure)
      end
    end

    context "with invalid rss entry" do
      let(:result) do
        Ox.parse(
          <<-XML
          <?xml version="1.0" ?>
          <rss><channel><item></item></channel></rss>
          XML
        )
      end

      it "raises whatever exception would be raised by internal code" do
        expect { described_class.retrieve_project_releases_rss_feed(name: name) }.to raise_error(NoMethodError)
      end
    end

    context "with correct rss entry" do
      let(:time_string) { "Sun, Feb 26 2006 16:36:49 GMT" }

      let(:result) do
        Ox.parse(
          <<-XML
          <?xml version="1.0" ?>
          <rss><channel><item><title>1.0.0</title><pubDate>#{time_string}</pubDate></item></channel></rss>
          XML
        )
      end

      it "returns processed data" do
        expect(described_class.retrieve_project_releases_rss_feed(name: name)).to eq([
          { number: "1.0.0", published_at: Time.parse(time_string) },
  ])
      end
    end
  end

  describe ".gather_raw_data_details" do
    let(:name) { "name" }
    let(:feed_releases) { [{ number: "0.1.1", published_at: "whenever" }] }

    before do
      allow(described_class).to receive(:retrieve_project_releases_rss_feed).with(name: name).and_return(feed_releases)
    end

    context "no releases missing details" do
      let(:raw_releases) { { "1.0.0" => [{}] } }

      it "returns no feed releases" do
        result = described_class.gather_raw_data_details(name: name, raw_releases: raw_releases)
        expect(result[:raw_release_objs].first.number).to eq("1.0.0")

        expect(result[:feed_releases]).to eq([])
        expect(described_class).not_to have_received(:retrieve_project_releases_rss_feed)
      end
    end

    context "one release missing details" do
      let(:raw_releases) { { "1.0.0" => [] } }

      it "returns feed releases" do
        result = described_class.gather_raw_data_details(name: name, raw_releases: raw_releases)
        expect(result[:raw_release_objs].first.number).to eq("1.0.0")

        expect(result[:feed_releases]).to eq(feed_releases)
        expect(described_class).to have_received(:retrieve_project_releases_rss_feed)
      end
    end
  end

  describe "#retrieve_license_details!" do
    # we are not trapping retrieval errors here, instead passing them up the chain
    let(:name) { "name" }
    let(:number) { "1.0.0" }
    let(:response) do
      { "info" => { "license" => license } }
    end
    let(:license) { "MIT" }
    let(:version) { described_class.new(number: number) }

    before do
      allow(described_class).to receive(:get).with("https://pypi.org/pypi/#{name}/#{number}/json").and_return(response)
    end

    it "can process a response" do
      # only test that we can get the value out and set it. dig has plenty of tests around its functionality
      version.retrieve_license_details!(name: name)

      expect(version.original_license).to eq(license)
    end
  end

  describe "#maybe_set_feed_published_at!" do
    let(:number) { "1.0.0" }
    let(:published_at) { Time.zone.now }
    let(:original_published_at) { nil }

    let(:version) { described_class.new(number: number, published_at: original_published_at) }

    context "with matching feed entry" do
      let(:feed_releases) { [{ number: number, published_at: published_at }] }

      context "with already set published at" do
        let(:original_published_at) { 1.hour.ago }

        it "does not update the current setting" do
          version.maybe_set_feed_published_at!(feed_releases: feed_releases)
          expect(version.published_at).to eq(original_published_at)
        end
      end

      it "updates the current setting" do
        version.maybe_set_feed_published_at!(feed_releases: feed_releases)
        expect(version.published_at).to eq(published_at)
      end
    end

    context "without matching feed entry" do
      let(:feed_releases) { [] }

      it "does not update the current setting" do
        version.maybe_set_feed_published_at!(feed_releases: feed_releases)
        expect(version.published_at).to eq(original_published_at)
      end
    end
  end
end
