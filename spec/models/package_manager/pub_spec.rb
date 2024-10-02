# frozen_string_literal: true

require "rails_helper"

describe PackageManager::Pub do
  let(:project) { create(:project, name: "foo", platform: described_class.formatted_name) }

  it 'has formatted name of "Pub"' do
    expect(described_class.formatted_name).to eq("Pub")
  end

  describe "#package_link" do
    let(:project) { create(:project, name: "foo", platform: described_class.formatted_name) }

    it "returns a link to project website" do
      expect(described_class.package_link(project)).to eq("https://pub.dartlang.org/packages/foo")
    end

    it "ignores version" do
      expect(described_class.package_link(project, "2.0.0")).to eq("https://pub.dartlang.org/packages/foo")
    end
  end

  describe "download_url" do
    it "returns a link to project tarball" do
      expect(described_class.download_url(project, "1.0.0")).to eq("https://storage.googleapis.com/pub.dartlang.org/packages/foo-1.0.0.tar.gz")
    end
  end

  describe "#documentation_url" do
    it "returns a link to project website" do
      expect(described_class.documentation_url(project)).to eq("http://www.dartdocs.org/documentation/foo/")
    end

    it "handles version" do
      expect(described_class.documentation_url(project, "2.0.0")).to eq("http://www.dartdocs.org/documentation/foo/2.0.0")
    end
  end

  describe ".dependencies" do
    context "when there are blank dependencies" do
      it "replaces blanks with '*' wildcards" do
        raw_project = VCR.use_cassette("pub/tecfy_corev2_package") do
          described_class.project("tecfy_corev2_package")
        end
        mapped_project = described_class.mapping(raw_project)
        dependencies = described_class.dependencies("tecfy_corev2_package", "1.0.1", mapped_project)

        expect(dependencies.pluck(:project_name, :requirements)).to match_array([
          ["flutter", "*"],
          ["flutter_localizations", "*"],
          ["tecfy_basic_package", "^1.1.11"],
          ["intl", "^0.17.0"],
          ["uuid", "^3.0.6"],
          ["expressions", "^0.2.4"],
          ["math_expressions", "^2.3.1"],
          ["web_socket_channel", "^2.2.0"],
          ["flutter_slidable", "^1.3.0"],
          ["localstorage", "^4.0.0+1"],
          ["path", "^1.8.1"],
          ["path_provider", "^2.0.11"],
          ["pull_to_refresh", "^2.0.0"],
          ["fl_chart", "^0.55.1"],
          ["soundpool", "^2.3.0"],
          ["soundpool_web", "^2.2.0"],
          ["flutter_staggered_animations", "^1.1.1"],
          ["flutter_material_color_picker", "^1.1.0+2"],
          ["google_maps_flutter", "^2.1.12"],
          ["google_maps_flutter_web", "^0.4.0+2"],
          ["http", "^0.13.5"],
          ["pdf", "^3.8.3"],
          ["printing", "^5.9.2"],
          ["ai_barcode", "^3.2.4"],
          ["permission_handler", "^9.2.0"],
          ["bot_toast", "^4.0.3"],
          ["url_launcher", "^6.1.5"],
          ["url_launcher_web", "^2.0.13"],
          ["image_picker_for_web", "^2.1.8"],
          ["shared_preferences_web", "^2.0.4"],
          ["date_time_picker", "^2.1.0"],
          ["firebase_core", "^1.21.0"],
          ["firebase_messaging", "^12.0.3"],
          ["universal_html", "^2.0.8"],
        ])
      end
    end
  end
end
