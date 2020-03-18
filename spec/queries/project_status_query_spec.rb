# frozen_string_literal: true

require "rails_helper"

describe ProjectStatusQuery do
  describe "#projects_by_name" do
    it "returns a list of projects by their requested names" do
      project = create(:project, platform: "Go", name: "known/project")

      instance = described_class.new("go", ["known/project"])

      expect(instance.projects_by_name).to eq({ "known/project" => project })
    end

    it "handles go project redirects" do
      project = create(:project, platform: "Go", name: "known/project")

      allow(PackageManager::Go)
        .to receive(:project_find_names)
        .with("unknown/project")
        .and_return(["known/project"])
      allow(PackageManager::Go)
        .to receive(:project_find_names)
        .with("second/unknown/project")
        .and_return(["other/unknown/project"])

      instance = described_class.new("Go", ["unknown/project", "second/unknown/project"])

      expect(instance.projects_by_name).to eq({ "unknown/project" => project })
    end
  end
end
