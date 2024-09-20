# frozen_string_literal: true

require "rails_helper"

describe PackageManager::Conda do
  let(:project) { create(:project, name: "foo", platform: described_class.formatted_name) }

  it 'has formatted name of "conda"' do
    expect(described_class.formatted_name).to eq("conda")
  end

  describe "#package_link" do
    it "returns a link to project website" do
      expect(described_class.package_link(project)).to eq("https://anaconda.org/anaconda/foo")
    end

    it "ignores version" do
      expect(described_class.package_link(project, "2.0.0")).to eq("https://anaconda.org/anaconda/foo")
    end
  end

  describe "#install_instructions" do
    it "returns a command to install the project" do
      expect(described_class.install_instructions(project)).to eq("conda install -c anaconda foo")
    end
  end

  describe ".dependencies" do
    context "when there are blank dependencies" do
      it "replaces blanks with '*' wildcards" do
        dependencies = VCR.use_cassette("conda/shap") do
          described_class.dependencies("shap", "0.46.0", nil)
        end

        expect(dependencies.pluck(:project_name, :requirements)).to match_array([
          ["cloudpickle", "*"],
          ["libgcc-ng", ">=11.2.0"],
          ["libstdcxx-ng", ">=11.2.0"],
          ["numba", "*"],
          ["numpy", ">=1.21.6,<2.0a0"],
          ["packaging", ">20.9"],
          ["pandas", "*"],
          ["python", ">=3.10,<3.11.0a0"],
          ["scikit-learn", "*"],
          ["scipy", "*"],
          ["slicer", "0.0.8"],
          ["tqdm", ">=4.27.0"],
        ])
      end
    end
  end
end
