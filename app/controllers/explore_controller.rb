class ExploreController < ApplicationController
  def index
    @platforms = Project.popular_platforms(:facet_limit => 40).first(28)
    @keywords = Project.popular_keywords(:facet_limit => 40).first(15)
    @languages = Project.popular_languages(:facet_limit => 40).first(21)
    @licenses = Project.popular_licenses(:facet_limit => 40).first(10)

    @trending_projects = Project.includes(:github_repository).recently_created.maintained.hacker_news.limit(10).to_a.uniq(&:name).first(6)
    @trending_repos = GithubRepository.trending.hacker_news.limit(10).to_a.uniq(&:full_name).first(6)
    @new_projects = Project.includes(:github_repository).maintained.order('projects.created_at desc').limit(6)
    @new_repos = GithubRepository.open_source.source.maintained.order('created_at desc').limit(6)
  end

  private

  helper_method :repo_search
  def repo_search(sort)
    search = search(GithubRepository, sort)
    ids = search.map{|r| r.id.to_i }
    indexes = Hash[ids.each_with_index.to_a]
    search.records.sort_by { |u| indexes[u.id] }
  end

  helper_method :project_search
  def project_search(sort)
    search = search(Project, sort)
    ids = search.map{|r| r.id.to_i }
    indexes = Hash[ids.each_with_index.to_a]
    search.records.sort_by { |u| indexes[u.id] }
  end

  def search(klass, sort)
    klass.search('', sort: sort, order: 'desc').paginate(per_page: 6, page: 1)
  end
end
