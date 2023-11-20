# frozen_string_literal: true

require "rails_helper"

describe NugetProjectVerificationWorker do
  let(:canonical_name) { "Newtonsoft.Json" }
  let(:name) { canonical_name }
  let(:project) { create(:project, :nuget, name: name) }

  before do
    allow(PackageManager::NuGet).to receive(:fetch_canonical_nuget_name)
      .and_return(canonical_name)
  end

  it "should use the low priority queue" do
    is_expected.to be_processed_in :small
  end

  context "name matches canonical" do
    let(:name) { canonical_name }
    it "doesn't touch project status" do
      expect { subject.perform(project.id) }.to not_change { project.reload.status }.from(nil)
    end
  end

  context "name differs from canonical" do
    let(:name) { canonical_name.upcase }

    it "marks project hidden" do
      expect { subject.perform(project.id) }.to change { project.reload.status }.from(nil).to("Hidden")
    end

    it "logs action performed" do
      expect(StructuredLog).to receive(:capture).with(
        "PROJECT_MARKED_NONCANONICAL",
        {
          platform: "nuget",
          name: project.name,
          canonical_name: canonical_name,
          project_id: project.id,
        }
      )

      subject.perform(project.id)
    end
  end

  context "when FETCH_CANONICAL_NAME_FAILED" do
    before do
      allow(PackageManager::NuGet).to receive(:fetch_canonical_nuget_name)
        .and_return(nil)
    end

    it "raises to retry" do
      expect { subject.perform(project.id) }.to raise_error(SidekiqQuietRetryError, "FETCH_CANONICAL_NAME_FAILED")
    end
  end

  context "when CANONICAL_NAME_ELEMENT_MISSING" do
    before do
      allow(PackageManager::NuGet).to receive(:fetch_canonical_nuget_name)
        .and_return(false)
    end

    context "when project removed" do
      let(:project) { create(:project, :nuget, :removed, name: name) }

      it "logs this expected case" do
        expect(StructuredLog).to receive(:capture).with(
          "CANONICAL_NAME_ELEMENT_MISSING_PROJECT_REMOVED",
          {
            platform: "nuget",
            name: project.name,
            canonical_name: false,
            project_id: project.id,
          }
        )

        subject.perform(project.id)
      end
    end

    context "when project not removed" do
      it "enqueues this project's status to be rechecked" do
        expect(CheckStatusWorker).to receive(:perform_async).with(project.id)

        subject.perform(project.id)
      end

      it "logs this not so expected case" do
        expect(StructuredLog).to receive(:capture).with(
          "CANONICAL_NAME_ELEMENT_MISSING_PROJECT_NOT_REMOVED",
          {
            platform: "nuget",
            name: project.name,
            canonical_name: false,
            project_id: project.id,
          }
        )

        subject.perform(project.id)
      end
    end
  end
end
