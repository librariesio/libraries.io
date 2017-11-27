class ProjectActivityController < ApplicationController
  before_action :find_project
  
  def show
    @all_counts = @project.repository_dependencies.where('repositories.fork = ?', false).joins(manifest: :repository).distinct('manifests.repository_id').group('repository_dependencies.requirements').count.select{|k,v| k.present? }
    @total = @all_counts.sum{|k,v| v }
    
    @activities = @project.dependency_activities.includes(:repository).paginate(page: page_number, per_page: 20) 
  end

end
