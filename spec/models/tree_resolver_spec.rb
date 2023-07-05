# frozen_string_literal: true

require "rails_helper"

RSpec.describe TreeResolver do
  let(:root_project) { create(:project, name: "root") }
  let(:root_version) { create(:version, project: root_project) }

  subject { described_class.new(root_version, "runtime", Date.today + 1.year) }

  context "with a single node tree" do
    it "produces the expected tree" do
      expected_tree = {
        version: { "number": root_version.number },
        dependency: { "platform": root_project.platform, "project_name": root_project.name, "kind": nil },
        requirements: nil,
        normalized_licenses: ["MIT"],
        dependencies: [],
      }

      expect(JSON.parse(subject.tree.to_json)).to eq(JSON.parse(expected_tree.to_json))
      expect(subject.project_names).to eq(["root"])
      expect(subject.license_names).to eq(["MIT"])
    end
  end

  context "with a typical tree" do
    it "produces the expected tree" do
      #       root
      #      /   \
      #    one   two
      #    /     /  \
      # three  four one
      one = create(:project, name: "one")
      two = create(:project, name: "two")
      three = create(:project, name: "three")
      four = create(:project, name: "four")
      one_version = create(:version, project: one)
      two_version = create(:version, project: two)
      three_version = create(:version, project: three)
      four_version = create(:version, project: four)
      one_dependency = create(:dependency, version: root_version, project: one, project_name: one.name, requirements: "> 0")
      two_dependency = create(:dependency, version: root_version, project: two, project_name: two.name, requirements: "> 0")
      three_dependency = create(:dependency, version: one_version, project: three, project_name: three.name, requirements: "> 0")
      four_dependency = create(:dependency, version: two_version, project: four, project_name: four.name, requirements: "> 0")
      deep_one_dependency = create(:dependency, version: two_version, project: one, project_name: one.name, requirements: "> 0")

      expected_tree = {
        version: { "number": root_version.number },
        dependency: { "platform": root_project.platform, "project_name": root_project.name, "kind": nil },
        requirements: nil,
        normalized_licenses: ["MIT"],
        dependencies: [
          {
            version: { "number": one_version.number },
            dependency: { "platform": one_dependency.platform, "project_name": one_dependency.project_name, "kind": "runtime" },
            requirements: "> 0",
            normalized_licenses: ["MIT"],
            dependencies: [
              {
                version: { "number": three_version.number },
                dependency: { "platform": three_dependency.platform, "project_name": three_dependency.project_name, "kind": "runtime" },
                requirements: "> 0",
                normalized_licenses: ["MIT"],
                dependencies: [],
              },
            ],
          },
          {
            version: { "number": two_version.number },
            dependency: { "platform": two_dependency.platform, "project_name": two_dependency.project_name, "kind": "runtime" },
            requirements: "> 0",
            normalized_licenses: ["MIT"],
            dependencies: [
              {
                version: { "number": four_version.number },
                dependency: { "platform": four_dependency.platform, "project_name": four_dependency.project_name, "kind": "runtime" },
                requirements: "> 0",
                normalized_licenses: ["MIT"],
                dependencies: [],
              },
              {
                version: { "number": one_version.number },
                dependency: { "platform": deep_one_dependency.platform, "project_name": deep_one_dependency.project_name, "kind": "runtime" },
                requirements: "> 0",
                normalized_licenses: ["MIT"],
                dependencies: [], # Dependencies truncated since this dependency already appears above
              },
            ],
          },
        ],
      }

      expect(JSON.parse(subject.tree.to_json)).to eq(JSON.parse(expected_tree.to_json))
      expect(subject.project_names).to match_array(%w[root one two three four])
      expect(subject.license_names).to eq(["MIT"])
    end
  end

  context "with pypi dependencies" do
    it "produces a tree with pypi filtered characters" do
      platform = "Pypi"
      root_project.update!(platform: platform)

      one = create(:project, name: "one", platform: platform)
      two = create(:project, name: "two", platform: platform)
      one_version = create(:version, project: one, number: "1.0.0")
      two_version = create(:version, project: two, number: "1.2.0")
      one_dependency = create(:dependency, version: root_version, project: one, project_name: one.name, platform: platform, requirements: "(> 0)")
      two_dependency = create(:dependency, version: root_version, project: two, project_name: two.name, platform: platform, requirements: "(> 0, >= 1.1)")

      expected_tree = {
        version: { "number": root_version.number },
        dependency: { "platform": root_project.platform, "project_name": root_project.name, "kind": nil },
        requirements: nil,
        normalized_licenses: ["MIT"],
        dependencies: [
          {
            version: { "number": one_version.number },
            dependency: { "platform": one_dependency.platform, "project_name": one_dependency.project_name, "kind": "runtime" },
            requirements: "(> 0)",
            normalized_licenses: ["MIT"],
            dependencies: [],
          },
          {
            version: { "number": two_version.number },
            dependency: { "platform": two_dependency.platform, "project_name": two_dependency.project_name, "kind": "runtime" },
            requirements: "(> 0, >= 1.1)",
            normalized_licenses: ["MIT"],
            dependencies: [],
          },
        ],
      }

      expect(JSON.parse(subject.tree.to_json)).to eq(JSON.parse(expected_tree.to_json))
      expect(subject.project_names).to match_array(%w[root one two])
      expect(subject.license_names).to eq(["MIT"])
    end
  end

  context "with a max-depth tree" do
    it "produces the truncated tree" do
      #    root
      #       \
      #        1
      #         \
      #          2
      #          ...
      previous_version = root_version
      projects = (1..described_class::MAX_TREE_DEPTH + 2).map do |i|
        project = create(:project, name: i)
        version = create(:version, project: project)
        dependency = create(:dependency, version: previous_version, project: project, project_name: project.name, requirements: "> 0")
        previous_version = version

        {
          dependency: dependency,
          project: project,
          version: version,
        }
      end

      terminal_dependency = projects[described_class::MAX_TREE_DEPTH - 1]
      expected_terminal_dependency = {
        version: { "number": terminal_dependency[:version][:number] },
        dependency: { "platform": terminal_dependency[:dependency].platform, "project_name": terminal_dependency[:dependency].project_name, "kind": terminal_dependency[:dependency].kind },
        requirements: "> 0",
        normalized_licenses: ["MIT"],
        dependencies: [],
      }

      terminal_dependency = JSON
        .parse(subject.tree.to_json)
        .dig(*["dependencies", 0] * described_class::MAX_TREE_DEPTH)

      expect(terminal_dependency).to eq(JSON.parse(expected_terminal_dependency.to_json))

      expected_project_names = projects[0..described_class::MAX_TREE_DEPTH].map { |p| p[:project].name } << "root"
      expect(subject.project_names).to match_array(expected_project_names)
      expect(subject.license_names).to eq(["MIT"])
    end
  end
end
