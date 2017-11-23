class GithubHookHandler
  VALID_ISSUE_ACTIONS = ["opened", "closed", "reopened", "labeled" "unlabeled", "edited"]

  def run(event, payload)
    case event
    when "create"
      case payload['ref_type']
      when "repository"
        run("repository", payload)
      when "tag"
        TagWorker.perform_async(payload["repository"]["full_name"])
      end
    when "issue_comment", "issues"
      return nil if event == "issues" && !VALID_ISSUE_ACTIONS.include?(payload["action"])

      IssueWorker.perform_async('GitHub', payload["repository"]["full_name"], payload["issue"]["number"], 'issue', nil)
    when "pull_request"
      IssueWorker.perform_async('GitHub', payload["repository"]["full_name"], payload["pull_request"]["number"], 'pull_request', nil)
    when "push"
      GithubHookWorker.perform_async(payload["repository"]["id"], payload["sender"]["id"])
    when "public", "release", "repository"
      CreateRepositoryWorker.perform_async("GitHub", payload["repository"]["full_name"], nil)
    when "watch"
      GithubStarWorker.perform_async(payload['repository']['full_name'])
    else
      puts "GithubHookHandler: received unknown '#{event}' event"
    end
  end
end
