require "rails_helper"

RSpec.describe TreeResolver do
  let(:root_project) { create(:project, name: "root") }
  let(:root_version) { create(:version, project: root_project) }

  subject { described_class.new(root_version, "runtime", Date.today + 1.year) }

  context "with a single node tree" do
    it "produces the expected tree" do
      expected_tree = {
        version: root_version,
        dependency: nil,
        requirements: nil,
        normalized_licenses: ["MIT"],
        dependencies: [],
      }

      expect(JSON.parse(subject.tree.to_json)).to eq(JSON.parse(expected_tree.to_json))
      expect(subject.project_names).to eq([])
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
        version: root_version,
        dependency: nil,
        requirements: nil,
        normalized_licenses: ["MIT"],
        dependencies: [
          {
            version: one_version,
            dependency: one_dependency,
            requirements: "> 0",
            normalized_licenses: ["MIT"],
            dependencies: [
              {
                version: three_version,
                dependency: three_dependency,
                requirements: "> 0",
                normalized_licenses: ["MIT"],
                dependencies: [],
              },
            ],
          },
          {
            version: two_version,
            dependency: two_dependency,
            requirements: "> 0",
            normalized_licenses: ["MIT"],
            dependencies: [
              {
                version: four_version,
                dependency: four_dependency,
                requirements: "> 0",
                normalized_licenses: ["MIT"],
                dependencies: [],
              },
              {
                version: one_version,
                dependency: deep_one_dependency,
                requirements: "> 0",
                normalized_licenses: ["MIT"],
                dependencies: [], # Dependencies truncated since this dependency already appears above
              },
            ],
          },
        ],
      }

      expect(JSON.parse(subject.tree.to_json)).to eq(JSON.parse(expected_tree.to_json))
      expect(subject.project_names).to match_array(["one", "two", "three", "four"])
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

      expected_terminal_dependency = {
        version: projects[described_class::MAX_TREE_DEPTH - 1][:version],
        dependency: projects[described_class::MAX_TREE_DEPTH - 1][:dependency],
        requirements: "> 0",
        normalized_licenses: ["MIT"],
        dependencies: [],
      }

      terminal_dependency = JSON
        .parse(subject.tree.to_json)
        .dig(*["dependencies", 0] * described_class::MAX_TREE_DEPTH)

      expect(terminal_dependency).to eq(JSON.parse(expected_terminal_dependency.to_json))
      expect(subject.project_names).to match_array(projects[0..described_class::MAX_TREE_DEPTH].map { |p| p[:project].name })
      expect(subject.license_names).to eq(["MIT"])
    end
  end
end

