# frozen_string_literal: true

require "rails_helper"

describe GithubHookHandler do
  describe "#run" do
    describe "create event" do
      context "repository" do
        it "runs a repository event" do
          params = {
            "ref_type" => "repository",
            "repository" => {},
          }

          expect(subject).to receive(:run).with("create", params).and_call_original
          expect(subject).to receive(:run).with("repository", params)

          subject.run("create", params)
        end
      end

      context "tag" do
        it "enqueues TagWorker" do
          expect(TagWorker).to receive(:perform_async)
          subject.run("create", { "ref_type" => "tag", "repository" => {} })
        end
      end
    end

    describe "push event" do
      it "enqueues GithubHookWorker" do
        expect(GithubHookWorker).to receive(:perform_async)
        subject.run("push", { "repository" => {}, "sender" => {} })
      end
    end

    describe "public, release, repository event" do
      it "enqueues CreateRepositoryWorker" do
        %w[public release repository].each do |event|
          expect(CreateRepositoryWorker).to receive(:perform_async)
          subject.run(event, { "repository" => {} })
        end
      end
    end

    describe "watch event" do
      it "enqueues a GithubStarWorker" do
        expect(GithubStarWorker).to receive(:perform_async)
        subject.run("watch", { "repository" => {} })
      end
    end
  end
end
