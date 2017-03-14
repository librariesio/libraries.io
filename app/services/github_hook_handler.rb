class GithubHookHandler
  def run(event, payload)
    case event
    when "push", "pull_request"
      GithubHookWorker.perform_async(payload["repository"]["id"], payload["sender"]["id"])
    else
      puts "GithubHookHandler: received unknown '#{event}' event"
    end
  end
end
