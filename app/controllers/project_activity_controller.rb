class ProjectActivityController < ApplicationController
  before_action :find_project

  def show
    original_scope = @project.dependency_activities
    scope = original_scope
    scope = original_scope.where(action: params[:type]) if params[:type].present?
    scope = original_scope.where(requirement: params[:requirements]) if params[:requirements].present?
    @all_counts = original_scope.group(:requirement).count.select{|k,v| k.present? }
    @types = original_scope.group(:action).count
    @total = DependencyActivity.where(project_id: @project.id).distinct.count(:repository_id)

    @activities = scope.includes(:repository)
                       .order('committed_at DESC')
                       .paginate(page: page_number, per_page: 20)
    @chart_data = scope.group(:action).group_by_month(:committed_at).count
  end

  private

  helper_method :sort_by_semver_range
  def sort_by_semver_range(limit)
    @all_counts.sort_by{|_k,v| -v}
               .first(limit)
               .sort_by{|k,_v|
                 k.gsub(/\~|\>|\<|\^|\=|\*|\s/,'')
                 .gsub('-','.')
                 .split('.').map{|i| i.to_i}
               }
  end
end
