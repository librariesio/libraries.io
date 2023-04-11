# frozen_string_literal: true

require "rails_helper"

describe PackageManager::Packagist do
  it 'has formatted name of "Packagist"' do
    expect(described_class.formatted_name).to eq("Packagist")
  end

  describe "#package_link" do
    let(:project) { create(:project, name: "foo", platform: described_class.formatted_name) }

    it "returns a link to project website" do
      expect(described_class.package_link(project)).to eq("https://packagist.org/packages/foo#")
    end

    it "handles version" do
      expect(described_class.package_link(project, "2.0.0")).to eq("https://packagist.org/packages/foo#2.0.0")
    end

    context "with drupal provider" do
      let(:project) { create(:project, name: "drupal/foo", platform: described_class.formatted_name) }

      let!(:version) { create(:version, project: project, repository_sources: ["Drupal"], number: "8.x-1.1") }

      it "handles version" do
        expect(described_class.package_link(project, "8.x-1.1")).to eq("https://www.drupal.org/project/foo/releases/8.x-1.1")
      end
    end
  end

  context "with an unmapped package" do
    subject do
      [
        {
          "name" =>	"librariesio/fakepkg",
          "description" => "A Libraries package.",
          "keywords" => ["php", "not-real"],
          "homepage" => "https://fakepkg.libraries.io",
          "version" => "v1.2.3",
          "version_normalized" => "1.2.3",
          "license" => ["BSD-3-Clause"],
          "authors" => [{"name" => "Fake Author", "email" => "fake.author@libraries.io"}],
          "source" => {"url" => "https://github.com/librariesio/fakepkg", "type" => "git", "reference" => "12341234123412341234"},
          "dist" => {},
          "type" => "library",
          "time" =>	"2012-09-18T06:46:25+00:00",
          "autoload" => {},
        }
      ]
    end

    describe ".mapping" do
      it "maps correctly" do
        expect(described_class.mapping(subject)).to include(
          name: "librariesio/fakepkg",
          description: "A Libraries package.",
          homepage: "https://fakepkg.libraries.io",
          keywords_array: ["php", "not-real"],
          licenses: "BSD-3-Clause",
          repository_url: "https://github.com/librariesio/fakepkg"
        )
      end
    end

    describe ".versions" do
      it "rejects dev branches that aren't really releases" do
        expect(described_class.versions(subject, "synergitech/cronitor")).to eq([{ number: "v1.2.3", published_at: "2012-09-18T06:46:25+00:00", original_license: ["BSD-3-Clause"] }])
      end
    end
  end

  describe "#deprecation_info" do
    it "return not-deprecated if 'abandoned' is false'" do
      expect(PackageManager::Packagist).to receive(:project).with("foo").and_return([{
                                                                                      "abandoned" => false,
                                                                                    }])

      expect(described_class.deprecation_info(project)).to eq({ is_deprecated: false, message: "" })
    end

    it "return deprecated if 'abandoned' is true'" do
      expect(PackageManager::Packagist).to receive(:project).with("foo").and_return([{
                                                                                      "abandoned" => true,
                                                                                    }])

      expect(described_class.deprecation_info(project)).to eq({ is_deprecated: true, message: "" })
    end

    it "return deprecated if 'abandoned' is set to a replacement package'" do
      expect(PackageManager::Packagist).to receive(:project).with("foo").and_return([{
                                                                                      "abandoned" => "use-this/package-instead",
                                                                                    }])

      expect(described_class.deprecation_info(project)).to eq({ is_deprecated: true, message: "Replacement: use-this/package-instead" })
    end
  end
end
