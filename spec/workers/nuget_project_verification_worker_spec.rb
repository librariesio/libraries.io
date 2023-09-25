# frozen_string_literal: true

require "rails_helper"

describe NugetProjectVerificationWorker do
  let(:canonical_name) { "Newtonsoft.Json" }
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
        { platform: "NuGet", name: name, canonical_name: canonical_name, project_id: project.id }
      )

      subject.perform(project.id)
    end
  end
end
