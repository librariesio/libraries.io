require 'rails_helper'

describe GithubHookHandler do
  describe "#run" do
    describe "create event" do
      context "repository" do
        it "runs a repository event" do
          params = {
            "ref_type" => "repository",
            "repository" => {}
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

    # describe "issue_comment event" do
    #   it "enqueues IssueWorker" do
    #     expect(IssueWorker).to receive(:perform_async)
    #     subject.run("issue_comment", { "issue" => {}, "repository" => {} })
    #   end
    # end
    #
    # describe "issues event" do
    #   context "valid action" do
    #     it "enqueues IssueWorker" do
    #       GithubHookHandler::VALID_ISSUE_ACTIONS.each do |action|
    #         expect(IssueWorker).to receive(:perform_async)
    #         subject.run("issues", { "action" => action, "issue" => {}, "repository" => {} })
    #       end
    #     end
    #   end
    #
    #   context "invalid action" do
    #     it "does not enqueue IssueWorker" do
    #       expect(IssueWorker).to_not receive(:perform_async)
    #       subject.run("issues", { "action" => "lala", "issue" => {}, "repository" => {} })
    #     end
    #   end
    # end

    describe "pull_request event" do
      let(:params) do
        {
          "action" => "opened",
          "repository" => {},
          "pull_request" => {},
          "sender" => {}
        }
      end

      it "runs pull request events" do
        expect(subject).to receive(:run).with("pull_request", params)

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
