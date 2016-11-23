class ExploreController < ApplicationController
  def index
    @platforms = Project.popular_platforms(:facet_limit => 40).first(28)
    @keywords = Project.popular_keywords(:facet_limit => 40).first(15)
    @languages = Project.popular_languages(:facet_limit => 40).first(21)
    @licenses = Project.popular_licenses(:facet_limit => 40).first(10)

    @trending_projects = trending_projects
    @trending_repos = trending_repos
  end

  private

  def trending_projects
    Project.includes(:github_repository).recently_created.maintained.hacker_news.to_a.uniq(&:name).first(6)
  end

  def trending_repos
    GithubRepository.trending.hacker_news.limit(10).to_a.uniq(&:name).first(6)
  end

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
