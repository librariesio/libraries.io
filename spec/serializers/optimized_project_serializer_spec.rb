# frozen_string_literal: true

require "rails_helper"

describe OptimizedProjectSerializer do
  let(:project_names) { projects.to_h { |p| [[p.platform, p.name], p.name] } }

  context "#serialize" do
    context "with projects" do
      let!(:projects) { create_list(:project, 3) }

      subject { described_class.new(projects, project_names) }

      it "should return all project fields" do
        result = subject.serialize
        expect(result.size).to be(3)
        expect(result[0].keys).to eq(
          OptimizedProjectSerializer::PROJECT_ATTRIBUTES + %i[
            keywords canonical_name name download_url forks latest_download_url
            package_manager_url repository_license repository_status
            stars versions contributions_count code_of_conduct_url
            contribution_guidelines_url funding_urls security_policy_url
          ]
        )
      end

      pending "when internal_key is true"

      context "with versions" do
        let(:project_1_versions) { create_list(:version, 5, project: projects[0]) }

        before { projects[0].versions = project_1_versions }

        it "should include versions" do
          result = subject.serialize
          expect(result.size).to be(3)

          expect(result.pluck(:versions).map(&:size)).to eq([5, 0, 0])
          expect(result[0][:versions]).to eq(
            project_1_versions.map do |v|
              {
                "number" => v.number,
                "published_at" => v.published_at,
                "original_license" => v.original_license,
                "status" => v.status,
                "repository_sources" => v.repository_sources,
              }
            end
          )
        end
      end
    end
  end
end
