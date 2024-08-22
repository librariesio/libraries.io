# frozen_string_literal: true

require "rails_helper"

describe PackageManager::Base do
  context "with a project from an arbitrary platform" do
    let(:project) { create(:project, name: "foo", platform: "Pypi") }

    let(:raw_project) do
      PackageManager::Pypi::JsonApiProject.new(
        {
          "info" => {
            "name" => project.name,
            "license" => "MIT",
            "summary" => "package summary",
            "home_page" => "https://www.libraries.io/package_name/home",
            "project_urls" => { "Source" => "https://www.libraries.io/package_name/source" },
          },
          "releases" =>
            {
              "1.0.0" => [{
                "upload_time" => 1.day.ago.iso8601,
                "yanked" => false,
                "yanked_reason" => nil,
              }],
            },
        }
      )
    end

    before do
      freeze_time
      allow(PackageManager::Pypi).to receive(:project).and_return(raw_project)
      allow(PackageManager::ApiService).to receive(:request_json_with_headers).and_return({})
      allow(PackageManager::Pypi::RssApiReleases).to receive(:request).and_return(
        instance_double(
          PackageManager::Pypi::RssApiReleases,
          releases: []
        )
      )
    end

    it "updates last_synced_at" do
      expect { PackageManager::Pypi.update(project.name) }
        .to change { project.reload.last_synced_at }.to(Time.now)
    end

    it "kicks off CheckStatusWorker after saving the project" do
      allow(CheckStatusWorker).to receive(:perform_async)
      PackageManager::Pypi.update(project.name)
      expect(CheckStatusWorker).to have_received(:perform_async).with(project.id)
    end

    context "when the status has been checked within past 1 day" do
      before { project.update_column(:status_checked_at, 1.hour.ago) }

      it "doesn't kick off CheckStatusWorker after saving the project" do
        allow(CheckStatusWorker).to receive(:perform_async)
        PackageManager::Pypi.update(project.name)
        expect(CheckStatusWorker).to_not have_received(:perform_async).with(project.id)
      end
    end
  end

  describe ".repo_fallback" do
    let(:result) { described_class.repo_fallback(repo, homepage) }

    let(:repo) { nil }
    let(:homepage) { nil }

    context "both nil" do
      it "returns blank" do
        expect(result).to eq("")
      end
    end

    context "repo nil, homepage not a url" do
      let(:homepage) { "test" }

      it "returns blank" do
        expect(result).to eq("")
      end
    end

    context "repo nil, homepage a non-repo url" do
      let(:homepage) { "http://homepage" }

      it "returns blank" do
        expect(result).to eq("")
      end
    end

    context "repo nil, homepage a repo url" do
      let(:homepage) { "https://github.com/librariesio/libraries.io" }

      it "returns blank" do
        expect(result).to eq("https://github.com/librariesio/libraries.io")
      end
    end

    context "repo not a url, homepage a url" do
      let(:repo) { "test" }
      let(:homepage) { "https://github.com/librariesio/libraries.io" }

      it "returns homepage" do
        expect(result).to eq("https://github.com/librariesio/libraries.io")
      end
    end

    context "repo not a repo url, homepage not a repo url" do
      let(:repo) { "http://repo" }
      let(:homepage) { "http://homepage" }

      it "returns repo" do
        expect(result).to eq("http://repo")
      end
    end
  end
end
