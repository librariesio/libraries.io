require 'rails_helper'

describe GithubHookHandler do
  describe "#run" do
    describe "issue_comment event" do
      it "enqueues IssueWorker" do
        expect(IssueWorker).to receive(:perform_async)
        subject.run("issue_comment", { "issue" => {}, "repository" => {} })
      end
    end

    describe "issues event" do
      context "valid action" do
        it "enqueues IssueWorker" do
          GithubHookHandler::VALID_ISSUE_ACTIONS.each do |action|
            expect(IssueWorker).to receive(:perform_async)
            subject.run("issues", { "action" => action, "issue" => {}, "repository" => {} })
          end
        end
      end

      context "invalid action" do
        it "does not enqueue IssueWorker" do
          expect(IssueWorker).to_not receive(:perform_async)
          subject.run("issues", { "action" => "lala", "issue" => {}, "repository" => {} })
        end
      end
    end

    describe "pull_request event" do
      let(:params) do
        {
          "action" => "opened",
          "repository" => {},
          "pull_request" => {},
          "sender" => {}
        }
      end

      it "runs issues and push events" do
        expect(subject).to receive(:run).with("pull_request", params).and_call_original
        expect(subject).to receive(:run).with("issues", params)#.and_call_original
        expect(subject).to receive(:run).with("push", params)#.and_call_original

        subject.run("pull_request", params)
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
