# frozen_string_literal: true

class Admin::StatsController < Admin::ApplicationController
  def index
    @recent_users = User.order("created_at DESC").limit(19)
    @recent_subscriptions = Subscription.where(repository_subscription_id: nil).order("created_at DESC").limit(7)
    @recent_watches = RepositorySubscription.order("created_at DESC").limit(7)

    @new_projects       = stats_for(Project)
    @new_versions       = stats_for(Version)
    @new_users          = stats_for(User)
    @new_subscriptions  = stats_for(Subscription)
    @new_repo_subs      = stats_for(RepositorySubscription)
    @new_web_hooks      = stats_for(WebHook)
  end

  def repositories
    @new_users          = stats_for(RepositoryUser)
    @new_manifests      = stats_for(Manifest)
    @new_orgs           = stats_for(RepositoryOrganisation)
  end

  def overview; end

  def api
    current_month_key = "api-usage-#{Date.today.strftime('%Y-%m')}"
    @api_key_usage = REDIS.hgetall(current_month_key)
    @api_keys = ApiKey.includes(:user).find(@api_key_usage.keys.map(&:to_i))
  end

  private

  def stats_for(klass)
    period = 3.days.ago.beginning_of_day
    klass.where("created_at > ?", period).group("date(created_at)").count.sort_by { |k, _v| k }.reverse
  end
end
