# frozen_string_literal: true

require "rails_helper"

describe PackageManager::Go do
  let(:project) { create(:project, name: "foo", platform: described_class.formatted_name) }
  let(:package_name) { "github.com/robfig/cron" }

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
      VCR.use_cassette("go/go_redirects") do
        expect(described_class.get_repository_url({ "Package" => "github.com/DarthSim/imgproxy" })).to eq("https://github.com/imgproxy/imgproxy")
      end
    end
  end

  describe "#mapping" do
    it "maps data correctly from pkg.go.dev" do
      VCR.use_cassette("go/pkg_go_dev") do
        project = described_class.project(package_name)
        mapping = described_class.mapping(project)
        expect(mapping[:description].blank?).to be false
        expect(mapping[:repository_url].blank?).to be false
        expect(mapping[:homepage].blank?).to be false
      end
    end
  end

  describe "#versions" do
    it "maps only major revision versions to module" do
      VCR.use_cassette("go/pkg_go_dev") do
        project = described_class.project("#{package_name}/v3")
        versions = described_class.versions(project, project[:name])

        expect(versions.find { |v| v[:number] == "v1.0.0" }).to be nil
        expect(versions.find { |v| v[:number] == "v3.0.0" }).to_not be nil
      end
    end

    it "maps latest version if no version list is available" do
      VCR.use_cassette("go/go_no_versions") do
        raw_project = { name: "github.com/BurntSushi/xgbutil" }

        versions = described_class.versions(raw_project, raw_project[:name])

        expect(versions.empty?).to be false
        expect(versions.find { |v| v[:number] == "v0.0.0-20190907113008-ad855c713046" }).to_not be nil
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


    it "should not match on a module name that is deceivingly similar to a major version" do
      name = "github.com/example/v2module1"
      matches = name.match(described_class::VERSION_MODULE_REGEX)

      expect(matches).to be nil
    end
  end

  describe "#one_version" do
    it "should update an individual version" do
      raw_project = nil

      VCR.use_cassette("go/pkg_go_dev") do
        raw_project = described_class.project(package_name)
      end

      VCR.use_cassette("version_update") do
        version = described_class.one_version(raw_project, "v1.2.0")
        expect(version[:number]).to eq "v1.2.0"
        expect(version[:original_license]).to eq "MIT"
        expect(version[:published_at].strftime("%m/%d/%Y")).to eq "05/05/2018"
      end
    end
  end

  describe "#update" do
    it "should update the non versioned module" do
      VCR.use_cassette("go/pkg_go_dev") do
        described_class.update("#{package_name}/v3")

        expect(Project.where(platform: "Go", name: package_name).exists?).to be true
      end
    end

    it "should update both the major release module and base module" do
      VCR.use_cassette("go/pkg_go_dev") do
        described_class.update(package_name)
        non_versioned_module = Project.find_by(platform: "Go", name: package_name)
        expect(non_versioned_module.versions.count).to eql 3
        expect(non_versioned_module.versions.where("number like ?", "v3%").count).to eql 0
        expect(non_versioned_module.versions.where("number like ?", "v1%").count).to be > 0

        described_class.update("#{package_name}/v3")
        versioned_module = Project.find_by(platform: "Go", name: "#{package_name}/v3")

        expect(versioned_module.versions.count).to eql 3
        expect(versioned_module.versions.where("number like ?", "v3%").count).to eql 3

        expect(non_versioned_module.versions.count).to eql 6
        expect(non_versioned_module.versions.where("number like ?", "v3%").count).to eql 3
      end
    end

    it "should use known versions if we have the license" do
      project = create(:project, platform: "Go", name: package_name)
      publish_date = Time.current
      project.versions.create(number: "v1.2.0", published_at: publish_date, original_license: "MIT")

      VCR.use_cassette("go/pkg_go_dev") do
        described_class.update(package_name)

        expect(project.versions.count).to eql 3
        expect(project.versions.where("number like ?", "v1%").count).to eql 3
        expect(project.versions.find_by(number: "v1.2.0").published_at.to_date).to eql publish_date.to_date
      end
    end

    it "should refresh version if we do not have the license" do
      project = create(:project, platform: "Go", name: package_name)
      publish_date = Time.now
      project.versions.create(number: "v1.2.0", published_at: publish_date)

      VCR.use_cassette("go/pkg_go_dev") do
        described_class.update(package_name)

        expect(project.versions.count).to eql 3
        expect(project.versions.where("number like ?", "v1%").count).to be > 0
        expect(project.versions.find_by(number: "v1.2.0").published_at.strftime("%m/%d/%Y")).to eq "05/05/2018"
      end
    end

    it "should use the existing name of the project matching the lower case name" do
      create(:project, name: package_name.upcase, platform: "Go")

      VCR.use_cassette("go/pkg_go_dev") do
        project = described_class.update(package_name)

        expect(Project.where(platform: "Go").where("lower(name) = ?", package_name.downcase).count).to eql 1
        expect(project.name).to eql(package_name.upcase)
        expect(project.versions.count).to eql 3
        expect(project.versions.where("number like ?", "v1%").count).to be > 0
        expect(project.versions.find_by(number: "v1.2.0").published_at.strftime("%m/%d/%Y")).to eq "05/05/2018"
      end
    end

    it "should use existing name of project and versioned project matching repository url" do
      create(:project, name: package_name, platform: "Go", repository_url: "https://github.com/robfig/cRoN")

      VCR.use_cassette("go/pkg_go_dev") do
        described_class.update("#{package_name}/v3")
        versioned_module = Project.find_by(platform: "Go", name: "#{package_name}/v3")

        expect(versioned_module).to be_present
        expect(versioned_module.versions.count).to eql 3
        expect(versioned_module.versions.where("number like ?", "v3%").count).to eql 3

        non_versioned_module = Project.find_by(platform: "Go", name: package_name)
        expect(non_versioned_module).to be_present
        expect(non_versioned_module.versions.count).to eql 6
        expect(non_versioned_module.versions.where("number like ?", "v3%").count).to eql 3
      end
    end

    it "creates two projects if they share a repository but not a name" do
      VCR.use_cassette("go/pkg_go_dev") do
        first_project = described_class.update("github.com/imdario/mergo")
        expect(first_project).to be_present

        second_project = described_class.update("gopkg.in/imdario/mergo.v0")
        expect(second_project).to be_present
      end
    end

    it "creates base module if versioned module exists first" do
      versioned_module = create(:project, name: "#{package_name}/v3", platform: "Go", repository_url: "https://github.com/robfig/cron")

      VCR.use_cassette("go/pkg_go_dev") do
        described_class.update(versioned_module.name)

        expect(versioned_module).to be_present
        expect(versioned_module.versions.count).to eql 3
        expect(versioned_module.versions.where("number like ?", "v3%").count).to eql 3

        non_versioned_module = Project.find_by(platform: "Go", name: package_name)
        expect(non_versioned_module).to be_present
        expect(non_versioned_module.versions.count).to eql 6
        expect(non_versioned_module.versions.where("number like ?", "v3%").count).to eql 3
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
            .with("https://go.uber.org/multierr?go-get=1", { request: { timeout: 2 } })
            .and_return(Nokogiri::HTML(html))

          expect(described_class.project_find_names("go.uber.org/multierr"))
            .to eq(["github.com/uber-go/multierr"])
        end
      end

      context "with an unknown result" do
        it "returns the original name" do
          allow(described_class)
            .to receive(:get_html)
            .with("https://go.example.org/user/foo?go-get=1", { request: { timeout: 2 } })
            .and_return(Nokogiri::HTML("<html><body>Hello, world!</body></html>"))

          expect(described_class.project_find_names("go.example.org/user/foo"))
            .to eq(["go.example.org/user/foo"])
        end
      end
    end
  end

  describe "#encode_for_proxy" do
    [
      %w[test test],
      %w[BigTest !big!test],
      %w[BIGBIGTEST !b!i!g!b!i!g!t!e!s!t],
    ].each do |(test, expected)|
      it "should replace capital letters" do
        expect(PackageManager::Go.encode_for_proxy(test)).to eql(expected)
      end
    end
  end
end
