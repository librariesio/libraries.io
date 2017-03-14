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

    describe "public, repository event" do
      it "enqueues CreateRepositoryWorker" do
        ["public", "repository"].each do |event|
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
