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

    context "Maven" do
      versions = %w[3.7 3.8.1 4.11-beta-1 4.13-rc-1 1.2-SNAPSHOT 1.4.2-12]
      it_behaves_like "Detects valid versions in scheme", :MAVEN, versions
    end

    context "PEP440" do
      versions = %w[1.0 1.7.0 3.1.0rc1 5.4.0.dev0]
      it_behaves_like "Detects valid versions in scheme", :PEP440, versions
    end

    context "Semver" do
      versions = %w[1.0.0 1.7.0 3.1.0-rc1 5.4.0-dev0]
      it_behaves_like "Detects valid versions in scheme", :SEMVER, versions
    end

    context "Calver" do
      versions = %w[1000 2012.2.1 16.04 20.12.2]
      it_behaves_like "Detects valid versions in scheme", :CALVER, versions
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
    let(:project1) { create(:project, name: "project1", platform: "pypi") }
    let(:project2) { create(:project, name: "project2", platform: "maven") }
    let(:project3) { create(:project, name: "project3") }
    let(:project4) { create(:project, name: "project4") }
    let(:project1_versions) {
      create_versions(
        %w[1.0 1.7.0 3.1.0rc1 5.4.0.dev0],
        project1
      )
    }
    let(:project2_versions) {
      create_versions(
        %w[3.7 3.8.1 4.11-beta-1 4.13-rc-1 1.2-SNAPSHOT 1.4.2-12],
        project2
      )
    }
    let(:project3_versions) {
      create_versions(
        %w[3.7.1 3.8.1 4.11.2-beta-1 4.13.1 1.2.0-SNAPSHOT 1.4.2-12],
        project2
      )
    }
    let(:project4_versions) {
      create_versions(
        %w[3.7.1.3.5.6 3.8.1ab 4.11.2-beta-1 4 001],
        project4
      )
    }

    describe "Tally counting" do
      before(:example) do
        allow(JSON).to receive(:pretty_generate)
      end

      it "Detects PEP440" do
        project1_versions # prime db with project
        Rake::Task["version:scheme_counter"].execute
        expect(JSON).to have_received(:pretty_generate).with({
                               **blank_tallies,
                               pep440: 1
                             })
      end

      it "Detects Maven" do
        project2_versions # prime db with project
        Rake::Task["version:scheme_counter"].execute
        expect(JSON).to have_received(:pretty_generate).with({
                                                               **blank_tallies,
                                                               maven: 1
                                                             })
      end

      it "Detects Semver" do
        project3_versions # prime db with project
        Rake::Task["version:scheme_counter"].execute
        expect(JSON).to have_received(:pretty_generate).with({
                                                               **blank_tallies,
                                                               semver: 1
                                                             })
      end

      it "Detects Unknown" do
        project4_versions # prime db with project
        Rake::Task["version:scheme_counter"].execute
        expect(JSON).to have_received(:pretty_generate).with({
                                                               **blank_tallies,
                                                               unknown: 1,
                                                               unknown_versions: [
                                                                 [
                                                                   project4.platform,
                                                                   project4.name,
                                                                   project4.reload.versions.pluck(:number)
                                                                 ]
                                                               ]
                                                             })
      end
    end
  end
end

# 3.1.0.rc1
