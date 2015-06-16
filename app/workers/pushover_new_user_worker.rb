class PushoverNewUserWorker
  include Sidekiq::Worker

  def perform(user_id)
    user = User.find(user_id)
    Pushover.notification({
      title: "@#{user.nickname} just signed up",
      message: "#{user.github_client.repos.length} repos and #{user.github_client.user(user.nickname).followers} followers",
      sound: 'bugle',
      url: user.github_url,
      url_title: 'View on Github'
    })
  end
end
