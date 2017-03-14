require 'rails_helper'

describe GithubHookHandler do
  describe "#run" do
    describe "issues event" do
      context "valid action" do
        it "enqueues IssueWorker" do
          ["opened", "closed", "reopened", "labeled" "unlabeled", "edited"].each do |action|
            expect(IssueWorker).to receive(:perform_async)
            subject.run("issues", { "action" => action, "issue" => {},"repository" => {} })
          end
        end
      end

      context "invalid action" do
        it "does not enqueue IssueWorker" do
          expect(IssueWorker).to_not receive(:perform_async)
          subject.run("issues", { "action" => "lala", "issue" => {},"repository" => {} })
        end
      end
    end

    describe "push, pull_request event" do
      it "enqueues GithubHookWorker" do
        ["push", "pull_request"]. each do |event|
          expect(GithubHookWorker).to receive(:perform_async)
          subject.run(event, { "repository" => {}, "sender" => {} })
        end
      end
    end

    describe "public, release, repository event" do
      it "enqueues CreateRepositoryWorker" do
        ["public", "release", "repository"].each do |event|
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
