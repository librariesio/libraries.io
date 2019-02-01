namespace :users do
  desc 'Sync users permissions'
  task sync_permissions: :environment do
    exit if ENV['READ_ONLY'].present?
    User.where(currently_syncing: false).optin.order('last_synced_at ASC').where('last_synced_at < ?', 1.week.ago).limit(100).each(&:update_repo_permissions_async)
  end

  task fix_auth_tokens: :environment do
    exit if ENV['READ_ONLY'].present?
    AuthToken.authorized.find_each do |token|
      token.update_attributes(login: token.github_client.user[:login], authorized: token.still_authorized?)
    end
  end
end
