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

  describe "#project" do
    it "returns raw project data from pkg.go.dev" do
      VCR.use_cassette("go/pkg_go_dev_is_a_module") do
        project = described_class.project("google.golang.org/grpc")
        expect(project[:name]).to eq("google.golang.org/grpc")
        expect(project[:html]).not_to be_nil
        expect(project[:overview_html]).not_to be_nil
      end
    end

    it "returns nil for packages that aren't go modules" do
      VCR.use_cassette("go/pkg_go_dev_not_a_module") do
        project = described_class.project("google.golang.org/grpc/examples/route_guide/routeguide")
        expect(project).to be nil
      end
    end

    it "finds canonical name from Go" do
      VCR.use_cassette("go/pkg_go_dev_v3") do
        project = described_class.project("github.com/RobFig/cron/v3")
        expect(project[:name]).to eql("github.com/robfig/cron/v3")
      end
    end
  end

  describe "#mapping" do
    it "maps data correctly from pkg.go.dev" do
      VCR.use_cassette("go/pkg_go_dev") do
        project = described_class.project(package_name)
        mapping = described_class.mapping(project)
        expect(mapping[:description]).to start_with("Package cron implements a cron spec parser")
        expect(mapping[:repository_url]).to eql("https://github.com/robfig/cron")
        expect(mapping[:homepage]).to eql("https://github.com/robfig/cron")
      end
    end

    context "with existing project" do
      # create a project that matches name with a different case
      let!(:existing_project) { create(:project, :go, name: name.upcase) }

      context "with non module name" do
        let(:name) { "github.com/robfig/cron" }

        it "finds existing project for non module name" do
          VCR.use_cassette("go/pkg_go_dev") do
            project = described_class.project(name)
            mapping = described_class.mapping(project)

            expect(mapping[:name]).to eql(existing_project.name)
          end
        end
      end

      context "with module name" do
        let(:name) { "github.com/robfig/cron/v3" }

        it "ignores existing name for module name" do
          VCR.use_cassette("go/pkg_go_dev") do
            project = described_class.project(name)
            mapping = described_class.mapping(project)

            expect(mapping[:name]).to eql(name)
          end
        end
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

    it "omits retracted versions" do
      VCR.use_cassette("go/pkg_with_retracted_versions") do
        raw_project = { name: "github.com/go-gorp/gorp/v3" }

        versions = described_class.versions(raw_project, raw_project[:name])

        expect(versions.find { |v| v[:number] == "v3.1.0" }).not_to be nil
        expect(versions.find { |v| v[:number] == "v3.0.0" }).to be nil
        expect(versions.find { |v| v[:number] == "v3.0.3" }).to be nil
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

  describe ".project_find_names(name)" do
    context "for names from a known host" do
      it "returns the name without calling the host" do
        name = "github.com/user/project"
        allow(described_class).to receive(:get_html)

        expect(described_class.project_find_names(name)).to eq([name])
        expect(described_class).to_not have_received(:get_html)
      end
    end

    context "for names from a host we ignore" do
      it "returns the name without calling the host" do
        name = "jfrog.com/some/git/repo"
        allow(described_class).to receive(:get_html)

        expect(described_class.project_find_names(name)).to eq([name])
        expect(described_class).to_not have_received(:get_html)
      end
    end

    context "for invalid hostnames" do
      it "returns the name without calling the host" do
        name = "not-even-a-legit-hostname"
        allow(described_class).to receive(:get_html)

        expect(described_class.project_find_names(name)).to eq([name])
        expect(described_class).to_not have_received(:get_html)
      end
    end

    context "for names with a known vcs" do
      it "returns the name" do
        name = "example.org/user/foo.hg"
        allow(described_class).to receive(:get_html)

        expect(described_class.project_find_names(name)).to eq([name])
        expect(described_class).to_not have_received(:get_html)
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

      context "with a request timeout" do
        before do
          allow(Bugsnag).to receive(:notify)
        end

        it "returns the original name", focus: true do
          allow(described_class)
            .to receive(:get_html)
            .with("https://go.example.org/user/foo?go-get=1", { request: { timeout: 2 } })
            .and_raise(Faraday::TimeoutError)

          expect(described_class.project_find_names("go.example.org/user/foo"))
            .to eq(["go.example.org/user/foo"])
          expect(Bugsnag).to have_received(:notify)
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

  describe ".remove_missing_versions" do
    let(:version_number_to_not_remove) { "1.0.0" }
    let(:version_number_to_remove) { "1.0.1" }
    let(:old_updated_at) { 5.years.ago.round }
    let(:version_to_remove_status) { nil }
    let!(:version_to_not_remove) { create(:version, project: project, number: version_number_to_not_remove, updated_at: old_updated_at) }
    let!(:version_to_remove) { create(:version, project: project, number: version_number_to_remove, updated_at: old_updated_at, status: version_to_remove_status) }

    before do
      # doesn't seem like the project has any version info unless it is reloaded explicitly
      project.versions.reload
    end

    it "should mark missing versions as Removed" do
      described_class.remove_missing_versions(project, [PackageManager::Base::ApiVersion.new(
        version_number: version_number_to_not_remove,
        published_at: nil,
        original_license: nil,
        runtime_dependencies_count: nil,
        repository_sources: nil,
        status: nil
      )])

      actual_version_to_not_remove = project.versions.find_by(number: version_number_to_not_remove)
      expect(actual_version_to_not_remove.status).to be nil
      expect(actual_version_to_not_remove.updated_at).to eq(old_updated_at)

      actual_version_to_remove = project.versions.find_by(number: version_number_to_remove)
      expect(actual_version_to_remove.status).to eq("Removed")
      expect(actual_version_to_remove.updated_at).to be_within(1.minute).of(Time.zone.now)
    end

    context "when the removed version is already removed" do
      let(:version_to_remove_status) { "Removed" }

      it "should not change anything" do
        described_class.remove_missing_versions(project, [PackageManager::Base::ApiVersion.new(
          version_number: version_number_to_not_remove,
          published_at: nil,
          original_license: nil,
          runtime_dependencies_count: nil,
          repository_sources: nil,
          status: nil
        )])

        actual_version_to_not_remove = project.versions.find_by(number: version_number_to_not_remove)
        expect(actual_version_to_not_remove.status).to be nil
        expect(actual_version_to_not_remove.updated_at).to eq(old_updated_at)

        actual_version_to_remove = project.versions.find_by(number: version_number_to_remove)
        expect(actual_version_to_remove.status).to eq("Removed")
        expect(actual_version_to_remove.updated_at).to eq(old_updated_at)
      end
    end
  end

  describe ".canonical_module_name" do
    it "maps only major revision versions to module" do
      VCR.use_cassette("go/pkg_go_dev") do
        result = described_class.canonical_module_name(package_name)
        expect(result).to eq(package_name)
      end
    end
  end

  describe ".dependencies" do
    let(:package_name) { "github.com/PuerkitoBio/goquery" }
    let(:version) { "v1.5.1" }

    it "parses dependencies from go.mod" do
      VCR.use_cassette("go/pkg_with_deps") do
        result = described_class.dependencies(package_name, version, nil)
        expect(result).to match_array(
          [
            ["github.com/andybalholm/cascadia", "v1.1.0"],
            ["golang.org/x/net", "v0.0.0-20200202094626-16171245cfb2"],
          ].map do |name, requirements, kind = "runtime"|
            {
              project_name: name,
              requirements: requirements,
              kind: kind,
              platform: "Go",
            }
          end
        )
      end
    end
  end
end
