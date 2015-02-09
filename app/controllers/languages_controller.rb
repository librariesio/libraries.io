class LanguagesController < ApplicationController
  def index
    @languages = GithubRepository.popular_languages
  end

  def show
    @language = params[:id]
    scope = Project.language(@language)
    raise ActiveRecord::RecordNotFound if scope.first.nil?
    @updated = scope.limit(5).order('updated_at DESC')
    @created = scope.limit(5).order('created_at DESC')
    @popular = scope.with_repo.limit(30)
      .order('github_repositories.stargazers_count DESC')
      .to_a.uniq(&:github_repository_id).first(5)
    @licenses = scope.popular_licenses.limit(8).to_a
  end
end
