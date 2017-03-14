require 'rails_helper'

describe GithubHookHandler do
  describe "#run" do
    describe "push, pull_request events" do
      it "enqueues GithubHookWorker" do
        ["push", "pull_request"]. each do |event|
          expect(GithubHookWorker).to receive(:perform_async)
          subject.run(event, { "repository" => {}, "sender" => {} })
        end
      end
    end

    describe "repository event" do
      it "enqueues CreateRepositoryWorker" do
        expect(CreateRepositoryWorker).to receive(:perform_async)
        subject.run("repository", { "repository" => {} })
      end
    end
  end
end
