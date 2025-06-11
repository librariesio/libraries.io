# frozen_string_literal: true

require "rails_helper"

describe ProjectStatusQuery do
  describe "#projects_by_name" do
    it "returns a list of projects by their requested names" do
      project = create(:project, platform: "Pypi", name: "foo")

      instance = described_class.new("Pypi", ["foo"])

      expect(instance.projects_by_name).to eq({ "foo" => project })
    end

    it "handles pypi normalized names" do
      project = create(:project, platform: "Pypi", name: "a-python-package")

      instance = described_class.new("Pypi", ["A___Python___Package"])

      expect(instance.projects_by_name).to eq({ "A___Python___Package" => project })
    end
  end
end
