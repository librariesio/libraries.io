require 'rails_helper'

describe PackageManager::Packagist do
  it 'has formatted name of "Packagist"' do
    expect(described_class.formatted_name).to eq('Packagist')
  end

  describe '#package_link' do
    let(:project) { create(:project, name: 'foo', platform: described_class.name) }

    it 'returns a link to project website' do
      expect(described_class.package_link(project)).to eq("https://packagist.org/packages/foo#")
    end

    it 'handles version' do
      expect(described_class.package_link(project, '2.0.0')).to eq("https://packagist.org/packages/foo#2.0.0")
    end
  end

  context "with an unmapped package" do
   subject do
      {
        "name" =>	"librariesio/fakepkg",
        "description" => "A Libraries package.",
        "time" =>	"2012-09-18T06:46:25+00:00",
        "maintainers" => [],
        "versions" => {
          "dev-master" => {"version" => "dev-master", "time" => "2020-01-08T08:45:45+00:00", "license" => ["BSD-3-Clause"], "name" =>	"librariesio/fakepkg", "description" => "A Libraries package."},
          "1.2.3" => {"version" => "1.2.3", "time" => "2020-01-08T08:45:45+00:00", "license" => ["BSD-3-Clause"], "name" =>	"librariesio/fakepkg", "description" => "A Libraries package."},
          "1.2.x-dev" => {"version" => "1.2.x-dev", "time" => "2020-01-08T08:45:45+00:00", "license" => ["BSD-3-Clause"], "name" =>	"librariesio/fakepkg", "description" => "A Libraries package."},
        },
        "type" =>	"library",
        "repository" => "https://github.com/librariesio/fakepkg"
      }
    end

    describe ".mapping" do
      it "maps correctly" do
        expect(described_class.mapping(subject)).to eq({
          name: "librariesio/fakepkg",
          description: "A Libraries package.",
          homepage: nil,
          keywords_array: [],
          licenses: "BSD-3-Clause",
          repository_url: "https://github.com/librariesio/fakepkg",
          versions: {
            "dev-master" => {"version" => "dev-master", "time" => "2020-01-08T08:45:45+00:00", "license" => ["BSD-3-Clause"], "name" =>	"librariesio/fakepkg", "description" => "A Libraries package."},
            "1.2.3" => {"version" => "1.2.3", "time" => "2020-01-08T08:45:45+00:00", "license" => ["BSD-3-Clause"], "name" =>	"librariesio/fakepkg", "description" => "A Libraries package."},
            "1.2.x-dev" => {"version" => "1.2.x-dev", "time" => "2020-01-08T08:45:45+00:00", "license" => ["BSD-3-Clause"], "name" =>	"librariesio/fakepkg", "description" => "A Libraries package."},
          }
        })
      end
    end

    describe ".versions" do
      it "rejects dev branches that aren't really releases" do
        expect(described_class.versions(subject, "librariesio/fakefpkg")).to eq([{number: "1.2.3", published_at: "2020-01-08T08:45:45+00:00"}])
      end
    end
  end
end
