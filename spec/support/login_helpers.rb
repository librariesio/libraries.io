# frozen_string_literal: true
module LoginHelpers
  def mock_is_admin(admin = true)
    allow_any_instance_of(User).to receive(:admin?).and_return(admin)
  end

  def mock_github_auth(user)
    user.identities << create(:identity) if user.identities.empty?
    OmniAuth.config.mock_auth[:github] = OmniAuth::AuthHash.new(
      provider:    'github',
      uid:         user.github_identity.uid,
      info:        {
        nickname: user.github_identity.nickname,
        email:    user.email
      },
      credentials: {
        token: user.github_identity.token
      }
    )
  end

  def login(user)
    mock_github_auth(user)
    visit '/auth/github'
  end
end

RSpec.configure do |config|
  config.include LoginHelpers
end
