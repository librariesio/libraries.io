# frozen_string_literal: true

require "rails_helper"

describe ProjectStatusQuery do
  describe "#projects_by_name" do
    it "returns a list of projects by their requested names" do
      project = create(:project, platform: "Pypi", name: "foo")

      instance = described_class.new("Pypi", ["foo"])

      expect(instance.projects_by_name).to eq({ "foo" => project })
    end

    it "omits projects that aren't found" do
      project = create(:project, platform: "Pypi", name: "foo")

      instance = described_class.new("Pypi", %w[foo bar])

      expect(instance.projects_by_name).to eq({ "foo" => project })
    end

    it "handles pypi lookups using unnormalized names against packages that would have the same normalized name" do
      project = create(:project, platform: "Pypi", name: "A-Python-Package")

      instance = described_class.new("Pypi", ["A___python___package"])

      expect(instance.projects_by_name).to eq({ "A___python___package" => project })
    end
  end
end
