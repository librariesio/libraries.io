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
