# frozen_string_literal: true

require "rails_helper"

describe PackageManager::Go do
  let(:project) { create(:project, name: "foo", platform: described_class.name) }

  it 'has formatted name of "Go"' do
    expect(described_class.formatted_name).to eq("Go")
  end

  describe "#package_link" do
    it "returns a link to project website" do
      expect(described_class.package_link(project)).to eq("https://pkg.go.dev/foo")
    end

    it "ignores version" do
      expect(described_class.package_link(project, "2.0.0")).to eq("https://pkg.go.dev/foo@2.0.0")
    end
  end

  describe "#documentation_url" do
    it "returns a link to project website" do
      expect(described_class.documentation_url("foo", "2.0.0")).to eq("https://pkg.go.dev/foo@2.0.0#section-documentation")
    end
  end

  describe "#install_instructions" do
    it "returns a command to install the project" do
      expect(described_class.install_instructions(project)).to eq("go get foo")
    end

    it "ignores version" do
      expect(described_class.install_instructions(project, "2.0.0")).to eq("go get foo")
    end
  end

  describe "#get_repository_url" do
    it "follows redirects to get correct url" do
      VCR.use_cassette("go_redirects") do
        expect(described_class.get_repository_url({ "Package" => "github.com/DarthSim/imgproxy" })).to eq("https://github.com/imgproxy/imgproxy")
      end
    end
  end

  describe "#mapping" do
    it "maps data correctly from pkg.go.dev" do
      VCR.use_cassette("pkg_go_dev") do
        project = described_class.project("github.com/urfave/cli")
        mapping = described_class.mapping(project)

        expect(mapping[:description].blank?).to be false
        expect(mapping[:repository_url].blank?).to be false
        expect(mapping[:homepage].blank?).to be false
        expect(mapping[:versions].count).to be > 0
      end
    end

    it "maps only major revision versions to module" do
      VCR.use_cassette("pkg_go_dev") do
        project = described_class.project("github.com/urfave/cli/v2")
        mapping = described_class.mapping(project)

        expect(mapping[:versions].find { |v| v[:number] == "v1.0.0" }).to be nil
        expect(mapping[:versions].find { |v| v[:number] == "v2.0.0" }).to_not be nil
      end
    end
  end

  describe "VERSION_MODULE_REGEX" do
    it "should match on module names with major revisions" do
      name = "github.com/example/module/v3"
      matches = name.match(described_class::VERSION_MODULE_REGEX)

      expect(matches).to_not be nil
      expect(matches[1]).to eql "github.com/example/module"
      expect(matches[2]).to eql "v3"
    end

    it "should not match on a module name without major revision" do
      name = "github.com/example/module"
      matches = name.match(described_class::VERSION_MODULE_REGEX)

      expect(matches).to be nil
    end
  end

  describe "#update" do
    it "should queue update for non versioned module" do
      VCR.use_cassette("pkg_go_dev") do
        expect(PackageManagerDownloadWorker).to receive(:perform_async).with(described_class.name, "github.com/urfave/cli")

        described_class.update("github.com/urfave/cli/v2")
      end
    end

    it "should update both the major release module and base module" do
      VCR.use_cassette("pkg_go_dev") do
        described_class.update("github.com/urfave/cli")
        non_versioned_module = Project.find_by(platform: "Go", name: "github.com/urfave/cli")
        expect(non_versioned_module.versions.count).to eql 39
        expect(non_versioned_module.versions.where("number like ?", "v2%").count).to eql 0
        expect(non_versioned_module.versions.where("number like ?", "v1%").count).to be > 0

        described_class.update("github.com/urfave/cli/v2")
        versioned_module = Project.find_by(platform: "Go", name: "github.com/urfave/cli/v2")
        expect(versioned_module.versions.count).to eql 8
        expect(versioned_module.versions.where("number like ?", "v2%").count).to eql 8

        expect(non_versioned_module.versions.where("number like ?", "v2%").count).to eql 8
      end
    end

    it "should use known versions" do
      project = create(:project, platform: "Go", name: "github.com/urfave/cli")
      publish_date = Time.now
      project.versions.create(number: "v1.3.0", published_at: publish_date)

      VCR.use_cassette("pkg_go_dev") do
        described_class.update("github.com/urfave/cli")

        expect(project.versions.count).to eql 39
        expect(project.versions.where("number like ?", "v1%").count).to be > 0
        expect(project.versions.find_by(number: "v1.3.0").published_at.to_date).to eql publish_date.to_date
      end
    end
  end

  describe ".project_find_names(name)" do
    context "for names from a a known host" do
      it "returns the name" do
        expect(described_class.project_find_names("github.com/user/project"))
          .to eq(["github.com/user/project"])
      end
    end

    context "for names with a known vcs" do
      it "returns the name" do
        expect(described_class.project_find_names("example.org/user/foo.hg"))
          .to eq(["example.org/user/foo.hg"])
      end
    end

    context "for other names" do
      context "with a redirect" do
        it "follows the redirect" do
          html = <<~EOHTML
            <!DOCTYPE html>
            <html>
                <head>
                    <meta name="go-import" content="go.uber.org/multierr git https://github.com/uber-go/multierr">
                    <meta name="go-source" content="go.uber.org/multierr https://github.com/uber-go/multierr https://github.com/uber-go/multierr/tree/master{/dir} https://github.com/uber-go/multierr/tree/master{/dir}/{file}#L{line}">
                    <meta http-equiv="refresh" content="0; url=https://godoc.org/go.uber.org/multierr">
                </head>
                <body>
                    Nothing to see here. Please <a href="https://godoc.org/go.uber.org/multierr">move along</a>.
                </body>
            </html>
          EOHTML

          allow(described_class)
            .to receive(:get_html)
            .with("https://go.uber.org/multierr?go-get=1")
            .and_return(Nokogiri::HTML(html))

          expect(described_class.project_find_names("go.uber.org/multierr"))
            .to eq(["github.com/uber-go/multierr"])
        end
      end

      context "with an unknown result" do
        it "returns the original name" do
          allow(described_class)
            .to receive(:get_html)
            .with("https://go.example.org/user/foo?go-get=1")
            .and_return(Nokogiri::HTML("<html><body>Hello, world!</body></html>"))

          expect(described_class.project_find_names("go.example.org/user/foo"))
            .to eq(["go.example.org/user/foo"])
        end
      end
    end
  end
end
