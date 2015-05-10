class StatsController < ApplicationController
  newrelic_ignore

  def index
    period              = 5.days.ago.beginning_of_day
    @new_projects       = Project.where('created_at > ?', period).group("date(created_at)").count.sort_by{|k,v| k }.reverse
    @new_repos          = GithubRepository.where('created_at > ?', period).group("date(created_at)").count.sort_by{|k,v| k }.reverse
    @new_github_users   = GithubUser.where('created_at > ?', period).group("date(created_at)").count.sort_by{|k,v| k }.reverse
    @new_users          = User.where('created_at > ?', period).group("date(created_at)").count.sort_by{|k,v| k }.reverse
    @new_subscriptions  = Subscription.where('created_at > ?', period).group("date(created_at)").count.sort_by{|k,v| k }.reverse
    @new_versions       = Version.where('created_at > ?', period).group("date(created_at)").count.sort_by{|k,v| k }.reverse

    @new_manifests      = Manifest.where('created_at > ?', period).group("date(created_at)").count.sort_by{|k,v| k }.reverse
    @new_repo_subs      = RepositorySubscription.where('created_at > ?', period).group("date(created_at)").count.sort_by{|k,v| k }.reverse
    @new_readmes        = Readme.where('created_at > ?', period).group("date(created_at)").count.sort_by{|k,v| k }.reverse

    # repo deps
    # deps
    # github contributions
    # github orgs
    # github tags

    # readme


  end
end
