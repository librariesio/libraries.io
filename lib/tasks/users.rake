namespace :users do
  desc 'Sync users permissions'
  task sync_permissions: :environment do
    User.where(currently_syncing: false).where('last_synced_at < ?', 1.week.ago).limit(1000).find_each(&:update_repo_permissions_async)
  end
end
