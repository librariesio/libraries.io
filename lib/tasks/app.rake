namespace :app do
  desc 'remove private data'
  task remove_private_data: :environment do
    if Rails.env.development?
      User.delete_all
      AuthToken.delete_all
      ApiKey.delete_all
      Repository.where(private: true).find_each do |repo|
        begin
          repo.destroy
        rescue Elasticsearch::Transport::Transport::Errors::NotFound
          nil
        end
      end
      Subscription.delete_all
      WebHook.delete_all
    end
  end
end
