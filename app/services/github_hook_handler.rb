# frozen_string_literal: true

class GithubHookHandler
  VALID_ISSUE_ACTIONS = ["opened", "closed", "reopened", "labeled" "unlabeled", "edited"].freeze

  def run(event, payload)
    case event
    when "create"
      case payload["ref_type"]
      when "repository"
        run("repository", payload)
      when "tag"
        TagWorker.perform_async(payload["repository"]["full_name"])
      end
    when "issue_comment", "issues", "pull_request"
      nil # noop
    when "push"
      GithubHookWorker.perform_async(payload["repository"]["id"], payload.dig("sender", "id"))
    when "public", "release", "repository"
      CreateRepositoryWorker.perform_async("GitHub", payload["repository"]["full_name"], nil)
    when "watch"
      GithubStarWorker.perform_async(payload["repository"]["full_name"])
    else
      puts "GithubHookHandler: received unknown '#{event}' event"
    end
  end
end
