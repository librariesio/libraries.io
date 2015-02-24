class StatsController < ApplicationController
  newrelic_ignore

  def index
    period = 5.days.ago
    @new_projects = Project.where('created_at > ?', period).group("date(created_at)").count.sort_by{|k,v| k }.reverse
    @new_versions = Version.where('created_at > ?', period).group("date(created_at)").count.sort_by{|k,v| k }.reverse
    @new_repos = GithubRepository.where('created_at > ?', period).group("date(created_at)").count.sort_by{|k,v| k }.reverse
    @new_github_users = GithubUser.where('created_at > ?', period).group("date(created_at)").count.sort_by{|k,v| k }.reverse
    @new_contributions = GithubContribution.where('created_at > ?', period).group("date(created_at)").count.sort_by{|k,v| k }.reverse
    @new_dependencies = Dependency.where('created_at > ?', period).group("date(created_at)").count.sort_by{|k,v| k }.reverse
    @new_users = User.where('created_at > ?', period).group("date(created_at)").count.sort_by{|k,v| k }.reverse
    @new_subscriptions = Subscription.where('created_at > ?', period).group("date(created_at)").count.sort_by{|k,v| k }.reverse
    @new_readmes = Readme.where('created_at > ?', period).group("date(created_at)").count.sort_by{|k,v| k }.reverse
  end
end
