# frozen_string_literal: true
require "rails_helper"
require "rake"

describe "version:scheme_counter" do
  describe "Scheme detection" do
    shared_examples "Detects valid versions in scheme" do |scheme, versions|
      versions.each do |version|
        it "#{version} validates as #{scheme}" do
          expect(VersionSchemeDetection::VALIDATORS[scheme].call(version)).to be_truthy
        end
      end
    end

    [
      ["Maven", %w[3.7 3.8.1 4.11-beta-1 4.13-rc-1 1.2-SNAPSHOT 1.4.2-12]],
      ["PEP440", %w[1.0 1.7.0 3.1.0rc1 5.4.0.dev0]],
      ["Semver", %w[1.0.0 1.7.0 3.1.0-rc1 5.4.0-dev0]],
      ["Calver", %w[1000 2012.2.1 16.04 20.12.2]]
    ].each do |params|
      scheme, versions = params
      context scheme do
        it_behaves_like "Detects valid versions in scheme", scheme.upcase.to_sym, versions
      end
    end
  end

  describe "Rake task" do
    Rails.application.load_tasks

    def create_versions(versions, project)
      versions.each do |version|
        create(:version, project: project, number: version)
      end
    end

    let(:blank_tallies) {{ semver: 0, pep440: 0, maven: 0, calver: 0, unknown: 0, no_versions: 0, unknown_versions: []}}

    describe "Tally counting" do
      before(:example) do
        allow(JSON).to receive(:pretty_generate)
      end

      shared_examples "Detects scheme" do |expect|
        let!(:project_versions) { create_versions( versions, project ) }

        it "Detects scheme" do
          tempfile = Tempfile.open([project.name, ".csv"]) do |tempfile_handle|
            csv = CSV.new(tempfile_handle)
            csv << [project.platform, project.name]
          end

          Rake::Task["version:scheme_counter"].execute(package_list: tempfile.path)
          expect(JSON).to have_received(:pretty_generate).with({ **blank_tallies, **expect })
        end
      end

      context "PEP440" do
        let(:project) { create(:project, platform: "pypi") }
        let(:versions) { %w[1.0 1.7.0 3.1.0rc1 5.4.0.dev0] }

        it_should_behave_like "Detects scheme", { pep440: 1 }
      end

      context "Maven" do
        let(:project) { create(:project, platform: "maven") }
        let(:versions) { %w[3.7 3.8.1 4.11-beta-1 4.13-rc-1 1.2-SNAPSHOT 1.4.2-12] }

        it_should_behave_like "Detects scheme", { maven: 1 }
      end

      context "Semver" do
        let(:project) { create(:project) }
        let(:versions) { %w[3.7.1 3.8.1 4.11.2-beta-1 4.13.1 1.2.0-SNAPSHOT 1.4.2-12] }

        it_should_behave_like "Detects scheme", { semver: 1 }
      end

      context "Unknown" do
        let(:project) { create(:project) }
        let(:versions) {  %w[3.7.1.3.5.6 3.8.1ab 4.11.2-beta-1 4 001] }

        it_should_behave_like "Detects scheme", {
          unknown: 1,
          unknown_versions: [
            [
              project4.platform,
              project4.name,
              project4.reload.versions.pluck(:number)
            ]
          ]
        }
      end
    end
  end
end