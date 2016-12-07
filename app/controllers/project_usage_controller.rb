class ProjectUsageController < ApplicationController
  before_action :find_project
  def show
    @all_counts = @project.repository_dependencies.where('github_repositories.fork = ?', false).joins(manifest: :github_repository).distinct('manifests.github_repository_id').group('repository_dependencies.requirements').count
    @total = @all_counts.sum{|k,v| v }
    if @all_counts.any?
      @kinds = @project.repository_dependencies.where('github_repositories.fork = ?', false).joins(manifest: :github_repository).distinct('manifests.github_repository_id').group('repository_dependencies.kind').count
      @counts = sort_by_semver_range(18)
      @highest_percentage = @counts.map{|_k,v| v.to_f/@total*100 }.max
      scope = @project.dependent_repositories.open_source.source
      scope = scope.where("repository_dependencies.requirements = ?", params[:requirements]) if params[:requirements].present?
      scope = scope.where("repository_dependencies.kind = ?", params[:kind]) if params[:kind].present?
      @repos = scope.paginate(page: page_number, per_page: 20)
    end
  end

  private

  helper_method :sort_by_semver_range
  def sort_by_semver_range(limit)
    @all_counts.sort_by{|_k,v| -v}
               .first(limit)
               .select{|k,v| k.present? }
               .sort_by{|k,_v|
                 k.gsub(/\~|\>|\<|\^|\=|\*|\s/,'')
                 .gsub('-','.')
                 .split('.').map{|i| i.to_i}
               }
  end
end
