# frozen_string_literal: true

require "rails_helper"

RSpec.describe Repository::PersistRepositoryFromUpstream do
  describe "#create_or_update_from_host_data" do
    let(:raw_upstream_data) { build(:raw_upstream_data) }

    it "creates a new Repository" do
      expect { described_class.create_or_update_from_host_data(raw_upstream_data) }.to change(Repository, :count).from(0).to(1)
    end

    it "assigns the correct data to the Repository" do
      described_class.create_or_update_from_host_data(raw_upstream_data)

      expected_attributes = described_class.raw_data_repository_attrs(raw_upstream_data)

      expect(Repository.first.attributes.symbolize_keys).to include(**expected_attributes)
    end

    context "with existing repository" do
      let!(:existing_repository) { create(:repository, full_name: raw_upstream_data.full_name) }

      it "does not create a new Repository" do
        expect { described_class.create_or_update_from_host_data(raw_upstream_data) }.not_to change(Repository, :count)
        expect(Repository.first.id).to eql(existing_repository.id)
      end

      it "updates existing repository" do
        described_class.create_or_update_from_host_data(raw_upstream_data)

        expected_attributes = described_class.raw_data_repository_attrs(raw_upstream_data)

        expect(Repository.find(existing_repository.id).attributes.symbolize_keys).to include(**expected_attributes)
      end
    end
  end

  describe "#update_from_host_data" do
    let(:raw_upstream_data) { build(:raw_upstream_data) }
    let(:existing_repository) { create(:repository) }

    it "updates existing repository" do
      described_class.update_from_host_data(existing_repository, raw_upstream_data)

      expected_attributes = described_class.raw_data_repository_attrs(raw_upstream_data)

      expect(Repository.find(existing_repository.id).attributes.symbolize_keys).to include(**expected_attributes)
    end
  end

  describe "#remove_repository_name_clash" do
    let(:full_name) { "test/clash" }
    let(:existing_repository) { create(:repository, full_name: full_name) }

    before do
      allow_any_instance_of(Repository).to receive(:update_from_repository).and_return(true)
    end

    it "doesn't destroy clash on name" do
      described_class.remove_repository_name_clash(existing_repository.host_type, existing_repository.full_name)

      expect(Repository.find_by(id: existing_repository.id)).not_to be_nil
    end

    context "with removed status" do
      let(:existing_repository) { create(:repository, full_name: full_name, status: "Removed") }

      it "destroys the removed repository" do
        described_class.remove_repository_name_clash(existing_repository.host_type, existing_repository.full_name)

        expect(Repository.find_by(id: existing_repository.id)).to be_nil
      end
    end

    context "with failure to update" do
      before do
        allow_any_instance_of(Repository).to receive(:update_from_repository).and_return(nil)
      end

      it "destroys the removed repository" do
        described_class.remove_repository_name_clash(existing_repository.host_type, existing_repository.full_name)

        expect(Repository.find_by(id: existing_repository.id)).to be_nil
      end
    end
  end

  describe "#find_repository_from_host_data" do
    let!(:existing_repository) { create(:repository, full_name: "find/me", uuid: "12345") }

    it "matches on uuid" do
      incoming_repository_data = build(:raw_upstream_data, full_name: "something/else", repository_uuid: existing_repository.uuid)

      expect(described_class.find_repository_from_host_data(incoming_repository_data)).to eql(existing_repository)
    end

    it "matches on lowercased full_name" do
      incoming_repository_data = build(:raw_upstream_data, full_name: "FIND/ME", repository_uuid: "something_else")

      expect(described_class.find_repository_from_host_data(incoming_repository_data)).to eql(existing_repository)
    end
  end

  describe "#correct_status_from_upstream" do
    let(:status) { nil }
    let(:repository) { build(:repository, status: status) }

    context "with nil status repository" do
      let(:status) { nil }

      context "with archived upstream repo" do
        it "should suggest unmaintained status" do
          expect(described_class.correct_status_from_upstream(repository, archived_upstream: true)).to eql("Unmaintained")
        end
      end

      context "with non archived upstream repo" do
        it "should suggest nil status" do
          expect(described_class.correct_status_from_upstream(repository, archived_upstream: false)).to be_nil
        end
      end
    end

    context "with unmaintained status repository" do
      let(:status) { "Unmaintained" }

      context "with archived upstream repo" do
        it "should suggest unmaintained status" do
          expect(described_class.correct_status_from_upstream(repository, archived_upstream: true)).to eql("Unmaintained")
        end
      end

      context "with non archived upstream repo" do
        it "should suggest nil status" do
          expect(described_class.correct_status_from_upstream(repository, archived_upstream: false)).to be_nil
        end
      end
    end

    context "with hidden status repository" do
      let(:status) { "Hidden" }

      context "with archived upstream repo" do
        it "should suggest no change" do
          expect(described_class.correct_status_from_upstream(repository, archived_upstream: true)).to eql(status)
        end
      end

      context "with non archived upstream repo" do
        it "should suggest no change" do
          expect(described_class.correct_status_from_upstream(repository, archived_upstream: false)).to eql(status)
        end
      end
    end
  end

  describe "#raw_data_repository_attrs" do
    let(:raw_upstream_data) do
      build(:raw_upstream_data,
            archived: true,
            default_branch: "main",
            description: "description",
            fork: true,
            full_name: "test/repo",
            has_issues: false,
            has_wiki: false,
            homepage: "http://libraries.io",
            host_type: "GitHub",
            keywords: %w[key words],
            language: "ruby",
            license: "mit",
            name: "repo",
            owner: "test",
            parent: { full_name: "test/parent" },
            is_private: false,
            repository_uuid: "uuid",
            scm: "git",
            repository_size: 100)
    end

    it "has expected fields" do
      mapped = described_class.raw_data_repository_attrs(raw_upstream_data)

      expect(mapped.keys).to contain_exactly(
        :default_branch,
        :description,
        :fork,
        :fork_policy,
        :forks_count,
        :full_name,
        :has_issues,
        :has_pages,
        :has_wiki,
        :homepage,
        :host_type,
        :keywords,
        :language,
        :license,
        :logo_url,
        :mirror_url,
        :name,
        :open_issues_count,
        :private,
        :pull_requests_enabled,
        :pushed_at,
        :scm,
        :size,
        :source_name,
        :stargazers_count,
        :subscribers_count,
        :uuid
      )
    end

    it "has expected data" do
      mapped = described_class.raw_data_repository_attrs(raw_upstream_data)

      expect(mapped.symbolize_keys).to match(
        hash_including(
          default_branch: "main",
          description: "description",
          full_name: "test/repo",
          has_issues: false,
          has_wiki: false,
          homepage: "http://libraries.io",
          host_type: "GitHub",
          keywords: %w[key words],
          language: "ruby",
          license: "MIT",
          name: "repo",
          source_name: "test/parent",
          private: false,
          uuid: "uuid",
          scm: "git",
          size: 100
        )
      )
    end
  end
end
