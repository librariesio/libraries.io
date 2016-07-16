namespace :app do
  desc 'restart web dynos'
  task restart: :environment do
    require 'platform-api'
    heroku = PlatformAPI.connect_oauth(ENV['PLATFORM_API_TOKEN'])
    dynos = heroku.dyno.list(ENV['APP_NAME']).select{|d| d['name'].match(/^web|^worker/) }
    dynos.each { |d| heroku.dyno.restart(ENV['APP_NAME'], d['name']); sleep 30 }
  end

  desc 'remove private data'
  task remove_private_data: :environment do
    if Rails.env.development?
      User.delete_all
      AuthToken.delete_all
      ApiKey.delete_all
      GithubRepository.where(private: true).find_each do |repo|
        begin
          repo.destroy
        rescue Elasticsearch::Transport::Transport::Errors::NotFound
          nil
        end
      end
      Payola::Affiliate.delete_all
      Payola::Coupon.delete_all
      Payola::Sale.delete_all
      Payola::StripeWebhook.delete_all
      Payola::Subscription.delete_all
      SubscriptionPlan.delete_all
      Subscription.delete_all
      WebHook.delete_all
    end
  end
end
