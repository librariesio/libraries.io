namespace :subscriptions do
  desc 'Setup subscription plans'
  task setup: :environment do
    SubscriptionPlan.setup_plans
  end
end
