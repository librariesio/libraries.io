# frozen_string_literal: true

require "rails_helper"

describe RepositoryHost::Github do
  let(:repository) { create(:repository, host_type: "GitHub", full_name: "vuejs/vue") }
  let(:repository_host) { described_class.new(repository) }
  let!(:project) { create(:project, repository: repository) }

  subject(:repo_host) { described_class.new(repository) }

  describe "#update_from_host" do
    let(:readme_double) { instance_double(Readme) }
    let(:readme_unmaintained) { false }
    let!(:auth_token) { create(:auth_token) }

    before do
      allow(repository).to receive(:readme).and_return(readme_double)
      allow(readme_double).to receive(:unmaintained?).and_return(readme_unmaintained)
    end

    context "with archived status from Github" do
      let(:repository) { create(:repository, host_type: "Github", full_name: "test/archived") }

      before do
        VCR.insert_cassette("github/archived")
      end

      after do
        VCR.eject_cassette
      end

      context "with existing nil repository status" do
        let(:repository) { build(:repository, host_type: "GitHub", full_name: "test/archived", status: nil) }

        it "marks repository as unmaintained" do
          repo_host.update_from_host

          expect(repository.reload.unmaintained?).to be true
        end

        it "does not mark project as unmaintained" do
          repo_host.update_from_host

          expect(project.reload.unmaintained?).to be false
        end
      end

      context "with unmaintained readme" do
        let(:readme_unmaintained) { true }

        it "marks repository as unmaintained" do
          repo_host.update_from_host

          expect(repository.reload.unmaintained?).to be true
        end

        it "marks project as unmaintained" do
          repo_host.update_from_host

          expect(project.reload.unmaintained?).to be true
        end
      end
    end

    context "with non archived status from Github" do
      let(:repository) { create(:repository, host_type: "Github", full_name: "vuejs/vue", status: nil) }

      before do
        VCR.insert_cassette("github/vue")
      end

      after do
        VCR.eject_cassette
      end

      context "with existing unmaintained repository status" do
        let(:repository) { create(:repository, host_type: "GitHub", full_name: "vuejs/vue", status: "Unmaintained") }

        it "marks repository as unmaintained" do
          repo_host.update_from_host

          expect(repository.reload.unmaintained?).to be false
        end

        it "marks project as unmaintained" do
          repo_host.update_from_host

          expect(project.reload.unmaintained?).to be false
        end
      end

      context "with unmaintained readme" do
        let(:readme_unmaintained) { true }

        it "marks repository as unmaintained" do
          repo_host.update_from_host

          expect(repository.reload.unmaintained?).to be true
        end

        it "marks project as unmaintained" do
          repo_host.update_from_host

          expect(project.reload.unmaintained?).to be true
        end
      end
    end
  end
end
