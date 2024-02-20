# frozen_string_literal: true

require "rails_helper"

RSpec.describe PackageManager::MultipleSourcesBase::ProviderMap do
  subject(:provider_map) { described_class.new(prioritized_provider_infos: [provider_info_one, provider_info_two]) }

  let(:provider_info_one) do
    PackageManager::MultipleSourcesBase::ProviderInfo.new(
      identifier: "one",
      default: true,
      provider_class: :one
    )
  end

  let(:provider_info_two) do
    PackageManager::MultipleSourcesBase::ProviderInfo.new(
      identifier: "two",
      provider_class: :two
    )
  end

  let(:project) { create(:project) }
  let(:repository_sources) { [] }

  let!(:version) { create(:version, project: project, repository_sources: repository_sources) }

  before do
    # Unfortunately there's some interaction between Project, Version, and
    # their hooks that cause the project's versions association to be cached
    # with no versions. Force-reload the project so the above created
    # versions can be found.
    project.reload
  end

  describe "#providers_for" do
    context "with no repository sources" do
      it "returns default provider" do
        expect(provider_map.providers_for(project: project)).to eq([provider_info_one])
      end
    end

    # This is a not-great situation so we need to log it
    context "with bad repository sources" do
      let(:repository_sources) { %w[wow cool] }

      before do
        allow(StructuredLog).to receive(:capture)
          .with("PROJECT_REPOSITORY_SOURCE_PROVIDERS_MISSING", { project_id: project.id, project_providers: "wow,cool" })
      end

      it "returns default provider" do
        expect(provider_map.providers_for(project: project)).to eq([provider_info_one])

        expect(StructuredLog).to have_received(:capture)
          .with("PROJECT_REPOSITORY_SOURCE_PROVIDERS_MISSING", { project_id: project.id, project_providers: "wow,cool" })
      end
    end

    context "with one repository source known, one unknown" do
      let(:repository_sources) { %w[two three] }

      it "returns found provider" do
        expect(provider_map.providers_for(project: project)).to eq([provider_info_two])
      end
    end
  end

  describe "#preferred_provider_for_project" do
    let(:search_version) { "2.3.4" }

    context "with no version found" do
      it "returns default provider" do
        expect(provider_map.preferred_provider_for_project(project: project, version: search_version)).to eq(provider_info_one)
      end
    end

    context "with version found" do
      let(:search_version) { version.number }

      context "with no match" do
        it "returns default provider" do
          expect(provider_map.preferred_provider_for_project(project: project, version: search_version)).to eq(provider_info_one)
        end
      end

      context "with match" do
        let(:repository_sources) { %w[two] }

        it "returns found provider" do
          expect(provider_map.preferred_provider_for_project(project: project, version: search_version)).to eq(provider_info_two)
        end
      end
    end
  end
end
