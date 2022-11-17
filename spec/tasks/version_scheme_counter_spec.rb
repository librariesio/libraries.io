# frozen_string_literal: true
require "rails_helper"

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
      ["Calver", %w[1000 2012.2.1 16.04 20.12.2]],
      ["OSGi", %w[1 1.2 1.2.3 1.2.3.a1_2-3]]
    ].each do |params|
      scheme, versions = params
      context scheme do
        it_behaves_like "Detects valid versions in scheme", scheme.upcase.to_sym, versions
      end
    end
  end

  describe "Building where clause" do
    shared_examples "Builds where clause correctly" do
      it "Builds where clause correctly" do
        where_clause = VersionSchemeDetection.build_project_where_clause(projects)
        expect(Project.where(where_clause).count).to eq(Project.count)
      end
    end

    context "1 project" do
      let(:projects) {
        project = create(:project)

        [[project.platform, project.name]]
      }

      it_behaves_like "Builds where clause correctly"
    end

    context ">1 projects" do
      let(:projects) {
        project = create(:project)
        project2 = create(:project)

        [[project.platform, project.name], [project2.platform, project2.name]]
      }

      it_behaves_like "Builds where clause correctly"
    end
  end

  describe "Rake task" do
    def create_versions(versions, project)
      versions.each do |version|
        create(:version, project: project, number: version)
      end
    end

    let(:blank_tallies) { VersionSchemeDetection::TALLIES.clone.merge({cursor: 1, unknown_schemes: [], warnings: [], versionless_packages: []})}

    before(:example) do
      allow(JSON).to receive(:pretty_generate)
    end

    describe "Tally counting" do
      shared_examples "Detects scheme" do |expected|
        let!(:project_versions) { create_versions( versions, project ) }

        it "Detects scheme" do
          tempfile = Tempfile.open([project.name, ".csv"]) do |tempfile_handle|
            csv = CSV.new(tempfile_handle)
            csv << [project.platform, project.name]
          end

          Rake::Task["version:scheme_counter"].execute(package_list: tempfile.path)
          expect(JSON).to have_received(:pretty_generate).with({ **blank_tallies, **expected })
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

        it_should_behave_like "Detects scheme", { osgi: 1 }
      end

      context "Semver" do
        let(:project) { create(:project) }
        let(:versions) { %w[3.7.1 3.8.1 4.11.2-beta-1 4.13.1 1.2.0-SNAPSHOT 1.4.2-12] }

        it_should_behave_like "Detects scheme", { semver: 1 }
      end

      context "Unknown" do
        versions = %w[3.7.1.3.5.6 3.8.1ab 4.11.2-beta-1 4 001]
        let(:project) { create(:project, name: "unknown_scheme") }
        let(:versions) { versions }

        it_should_behave_like "Detects scheme", {
          unknown: 1,
          unknown_schemes: [
            [
              "Rubygems",
              "unknown_scheme",
              versions
            ]
          ]
        }
      end

      context "Not unanimous" do
        versions = %w[3.7.1 3.8.1 4.11.2 001]
        let(:project) { create(:project, name: "unknown_scheme") }
        let(:versions) { versions }

        it_should_behave_like "Detects scheme", {
          unknown: 1,
          unknown_schemes: [
            [
              "Rubygems",
              "unknown_scheme",
              versions
            ]
          ]
        }
      end
    end

    describe "Task recovery" do
      let(:project1) { create(:project) }
      let(:project2) { create(:project) }
      let(:project3) { create(:project) }

      output_file, tempfile = nil
      before do
        output_file = Tempfile.open do |fh|
          fh << { **VersionSchemeDetection::TALLIES, cursor: 2 }.to_json
        end

        tempfile = Tempfile.open do |fh|
          csv = CSV.new(fh)
          csv << [project1.platform, project1.name]
          csv << [project2.platform, project2.name]
          csv << [project3.platform, project3.name]
        end
      end

      after do
        File.unlink(output_file.path)
        File.unlink(tempfile.path)
      end

      it "Picks up where it left off" do
        Rake::Task["version:scheme_counter"].execute(package_list: tempfile.path, output_file: output_file.path)
        expect(JSON).to have_received(:pretty_generate).with({
                                                                     **blank_tallies,
                                                                     no_versions: 1,
                                                                     versionless_packages: [
                                                                       [project3.platform, project3.name],
                                                                     ],
                                                                     cursor: 3
                                                                   })
      end
    end
  end
end