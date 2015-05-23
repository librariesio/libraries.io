class PushoverNewUserWorker
  include Sidekiq::Worker

  def perform(user_id)
    user = User.find(user_id)
    Pushover.notification({
      title: "@#{user.nickname} just signed up",
      message: "#{user.repos.length} repos and #{user.github_client.user(user.nickname).followers} followers",
      user: 'ucf5rTWgQVwdSWDxNVL9yu67NSh7oy',
      token: 'ajpzy2SfieUCRVYbCCsL9UdHFyUFCF',
      sound: 'bugle',
      url: user.github_url,
      url_title: 'View on Github'
    })
  end
end
