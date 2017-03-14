class GithubHookHandler
  def run(event, payload)
    case event
    when "push", "pull_request"
      GithubHookWorker.perform_async(payload["repository"]["id"], payload["sender"]["id"])
    when "public", "repository"
      CreateRepositoryWorker.perform_async("GitHub", payload["repository"]["full_name"], nil)
    when "watch"
      GithubStarWorker.perform_async(payload['repository']['full_name'], nil)
    else
      puts "GithubHookHandler: received unknown '#{event}' event"
    end
  end
end
