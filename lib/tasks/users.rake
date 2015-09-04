namespace :users do
  desc 'Sync users permissions'
  task sync_permissions: :environment do
    User.find_each(&:update_repo_permissions_async)
  end
end
