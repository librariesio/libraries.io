# frozen_string_literal: true

require "rails_helper"

describe PackageManager::Base do
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
