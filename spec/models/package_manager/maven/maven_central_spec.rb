# frozen_string_literal: true

require "rails_helper"

describe PackageManager::Maven::MavenCentral do
  describe ".latest_version_scraped" do
    context "with all valid semver versions" do
      let(:html) do
        # Example HTML scraped from https://repo1.maven.org/maven2/io/github/caffetteria/data-service-opencmis/
        <<-HTML
          <html><body><main>
            <pre id="contents">
              <a href="../">../</a>
              <a href="0.1.0/" title="0.1.0/">0.1.0/</a>
              <a href="0.2.0/" title="0.2.0/">0.2.0/</a>
              <a href="0.2.1/" title="0.2.1/">0.2.1/</a>
              <a href="1.0.0/" title="1.0.0/">1.0.0/</a>
              <a href="1.0.1/" title="1.0.1/">1.0.1/</a>
              <a href="1.1.0/" title="1.1.0/">1.1.0/</a>
              <a href="1.1.1/" title="1.1.1/">1.1.1/</a>
              <a href="maven-metadata.xml" title="maven-metadata.xml">maven-metadata.xml</a>
            </pre>
          </main></body></html>
        HTML
      end

      before do
        allow(PackageManager::ApiService).to receive(:request_raw_data).and_return(html)
        allow(Bugsnag).to receive(:notify)
      end

      it "scrapes the maven HTML to find a real version" do
        expect(described_class.latest_version_scraped("foo:bar")).to eq("1.1.1")
        expect(Bugsnag).to_not have_received(:notify)
      end
    end

    context "with non-semver versions" do
      let(:html) do
        # Example portion of HTML scraped from https://repo1.maven.org/maven2/org/wso2/am/am-parent/
        <<-HTML
          <html><body><main>
            <pre id="contents">
              <a href="../">../</a>
              <a href="1.10.0/" title="1.10.0/">1.10.0/</a>                                           2016-01-07 12:19
              <a href="2.0.0/" title="2.0.0/">2.0.0/</a>                                            2016-07-27 19:45
              <a href="3.0.0/" title="3.0.0/">3.0.0/</a>                                            2018-04-11 21:37
              <a href="3.0.0-,3/" title="3.0.0-,3/">3.0.0-,3/</a>                                         2017-06-15 14:07
              <a href="maven-metadata.xml" title="maven-metadata.xml">maven-metadata.xml</a>
            </pre>
          </main></body></html>
        HTML
      end

      before do
        allow(PackageManager::ApiService).to receive(:request_raw_data).and_return(html)
        allow(Bugsnag).to receive(:notify)
      end

      it "scrapes the maven HTML and ignores non-semver versions to find a real version" do
        expect(described_class.latest_version_scraped("foo:bar")).to eq("3.0.0")
        expect(Bugsnag).to_not have_received(:notify)
      end
    end

    context "with no valid semver versions" do
      let(:html) do
        # Example portion of HTML scraped from https://repo1.maven.org/maven2/org/wso2/am/am-parent/
        <<-HTML
          <html><body><main>
            <pre id="contents">
              <a href="../">../</a>
              <a href="3.0.0-,3/" title="3.0.0-,3/">3.0.0-,3/</a>                                         2017-06-15 14:07
              <a href="maven-metadata.xml" title="maven-metadata.xml">maven-metadata.xml</a>
            </pre>
          </main></body></html>
        HTML
      end

      before do
        allow(PackageManager::ApiService).to receive(:request_raw_data).and_return(html)
        allow(Bugsnag).to receive(:notify)
      end

      it "scrapes the maven HTML and notifies us that there was no version found" do
        expect(described_class.latest_version_scraped("foo:bar")).to eq(nil)
        expect(Bugsnag).to have_received(:notify)
      end
    end

    context "with empty response" do
      # Example blank HTML from when we get a 404 back, e.g. https://repo1.maven.org/maven2/cljsjs/hammer
      let(:html) { "" }

      before do
        allow(PackageManager::ApiService).to receive(:request_raw_data).and_return(html)
        allow(Bugsnag).to receive(:notify)
      end

      it "translates a 404 response into a blank string and ultimately a nil response" do
        expect(described_class.latest_version_scraped("foo:bar")).to eq(nil)
        expect(Bugsnag).to_not have_received(:notify)
      end
    end
  end

  describe ".update" do
    context "with existing package with removed releases" do
      # several vulnerable releases of com.appdynamics:lambda-tracer were removed
      # from Maven Central: https://issues.sonatype.org/browse/OSSRH-49704
      let(:project_name) { "com.appdynamics:lambda-tracer" }
      let(:project) { Project.create(platform: "Maven", name: project_name) }

      # a version that was removed on Maven Central that we still know about
      let!(:remotely_removed_version) { project.versions.create(number: "1.0.2-1361", status: nil) }

      # a version that, as of November 2023, was still available on Maven Central
      let!(:existing_version) { project.versions.create(number: "1.1.1363", status: nil) }

      it "marks the remotely removed version as Removed" do
        VCR.use_cassette("maven-central/lambda-tracer") do
          described_class.update(project_name, sync_version: :all)
        end

        remotely_removed_version.reload
        existing_version.reload

        expect(remotely_removed_version.status).to eq("Removed")
        expect(existing_version.status).to eq(nil)
      end
    end
  end

  describe ".versions_from_html" do
    it "retrieves versions from Maven Central index HTML" do
      VCR.use_cassette("maven-central/lambda-tracer") do
        # Matching versions as of November 2023
        expect(described_class.versions_from_html("com.appdynamics:lambda-tracer")).to match_array(%w[1.1.1363 1.2.1390 20.03.1391 20.11.1400])
      end
    end
  end
end
