class ExploreController < ApplicationController
  def index
    @platforms = Project.popular_platforms(:facet_limit => 40).first(28)
    @keywords = Project.popular_keywords(:facet_limit => 40).first(15)
    @languages = Project.popular_languages(:facet_limit => 40).first(21)
    @licenses = Project.popular_licenses(:facet_limit => 40).first(10)

    @trending_projects = trending_projects
    @popular_projects = project_search('rank')
    @dependend_projects = project_search('dependents_count')

    @trending_repos = trending_repos
    @popular_repos = repo_search('stargazers_count')
    @forked_repos = repo_search('forks_count')
  end

  private

  def trending_projects
    Project.includes(:github_repository).recently_created.hacker_news.limit(6)
  end

  def trending_repos
    scope = GithubRepository.maintained.open_source.where.not(pushed_at: nil).recently_created.where('stargazers_count > 0')
    scope.hacker_news.limit(6)
  end

  def repo_search(sort)
    search = GithubRepository.search('', sort: sort, order: 'desc').paginate(per_page: 6, page: 1)
    search.records
  end

  def project_search(sort)
    search = Project.search('', sort: sort, order: 'desc').paginate(per_page: 6, page: 1)
    search.records
  end
end
