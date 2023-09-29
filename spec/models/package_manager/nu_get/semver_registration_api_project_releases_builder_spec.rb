# frozen_string_literal: true

require "rails_helper"

describe PackageManager::NuGet::SemverRegistrationApiProjectReleasesBuilder do
  # These tests ensure the method switches between the two modes by which
  # NuGet delivers releases: either in the project response or via a
  # pagniated-like interface using data URLs in the project response.
  describe ".build" do
    let(:project_name) { "Newtonsoft.Json" }

    context "with package with releases in project response" do
      it "loads the proper releases" do
        releases = VCR.use_cassette("nu_get/releases_builder/newtonsoft_json") do
          described_class.build(project_name: project_name).releases
        end

        expect(releases.first.version).to eq("3.5.8")
        expect(releases.last.version).to eq("13.0.3")
      end
    end

    context "with package with releases in paginated data urls" do
      let(:project_name) { "Microsoft.EntityFrameworkCore.SqlServer" }

      it "loads the proper releases" do
        releases = VCR.use_cassette("nu_get/releases_builder/microsoft_entityframeworkcore_sqlserver") do
          described_class.build(project_name: project_name).releases
        end

        expect(releases.first.version).to eq("0.0.1-alpha")
        expect(releases.last.version).to eq("8.0.0-rc.1.23419.6")
      end
    end
  end
end
