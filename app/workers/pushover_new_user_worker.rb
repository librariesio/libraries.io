class PushoverNewUserWorker
  include Sidekiq::Worker
  sidekiq_options queue: :user

  def perform(user_id)
    user = User.find(user_id)
    repos = user.github_client.repos.length
    followers = user.github_client.user(user.nickname).followers
    if repos > 10 || followers > 5
      Pushover.notification({
        title: "@#{user.nickname} just signed up",
        message: "#{repos} repos and #{followers} followers",
        sound: 'bugle',
        url: user.github_url,
        url_title: 'View on Github'
      })
    end
  end
end
