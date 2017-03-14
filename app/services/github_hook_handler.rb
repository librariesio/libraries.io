class GithubHookHandler
  def run(event, payload)
    case event
    when "issues"
      case payload["action"]
      when "opened", "closed", "reopened", "labeled" "unlabeled", "edited"
        IssueWorker.perform_async(payload["repository"]["full_name"], payload["issue"]["number"], nil)
      end
    when "pull_request"
      payload["issue"] ||= {}
      payload["issue"]["number"] = payload["pull_request"]["number"]

      run("issues", payload)
      run("push", payload)
    when "push"
      GithubHookWorker.perform_async(payload["repository"]["id"], payload["sender"]["id"])
    when "public", "release", "repository"
      CreateRepositoryWorker.perform_async("GitHub", payload["repository"]["full_name"], nil)
    when "watch"
      GithubStarWorker.perform_async(payload['repository']['full_name'], nil)
    else
      puts "GithubHookHandler: received unknown '#{event}' event"
    end
  end
end
