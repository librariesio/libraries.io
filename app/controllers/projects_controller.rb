class ProjectsController < ApplicationController
  def index
    @created = Project.few_versions.order('created_at DESC').limit(5).includes(:github_repository)
    @updated = Project.many_versions.order('updated_at DESC').limit(5).includes(:github_repository)
  end

  def show
    find_project
    @version_count = @project.versions.count
    @github_repository = @project.github_repository
    if @version_count.zero?
      @versions = []
      if @github_repository.present?
        @github_tags = @github_repository.github_tags.order('published_at DESC').limit(10).to_a.sort
        if params[:number].present?
          @version = @github_repository.github_tags.find_by_name(params[:number])
          raise ActiveRecord::RecordNotFound if @version.nil?
        end
      else
        @github_tags = []
      end
      if @versions.empty? && @github_tags.empty?
        raise ActiveRecord::RecordNotFound if params[:number].present?
      end
    else
      @versions = @project.versions.order('published_at DESC').limit(10).to_a.sort
      if params[:number].present?
        @version = @project.versions.find_by_number(params[:number])
        raise ActiveRecord::RecordNotFound if @version.nil?
      end
    end
    @dependencies = (@versions.any? ? (@version || @versions.first).dependencies.order('project_name ASC') : [])
    @github_repository = @project.github_repository
    @contributors = @project.github_contributions.order('count DESC').limit(20).includes(:github_user)
  end

  def dependents
    find_project
    page = params[:page].to_i > 0 ? params[:page].to_i : 1
    @dependents = WillPaginate::Collection.create(page, 30, @project.dependents_count) do |pager|
      pager.replace(@project.dependent_projects(page: page))
    end
  end

  def versions
    find_project
    @versions = @project.versions.order('published_at DESC').paginate(page: params[:page])
    respond_to do |format|
      format.html
      format.atom
    end
  end

  def tags
    find_project
    if @project.github_repository.nil?
      @tags = []
    else
      @tags = @project.github_repository.github_tags.order('published_at DESC').paginate(page: params[:page])
    end
    respond_to do |format|
      format.html
      format.atom
    end
  end

  private

  def find_project
    @project = Project.platform(params[:platform]).where('lower(name) = ?', params[:name].downcase).includes({:github_repository => :readme}).first
    raise ActiveRecord::RecordNotFound if @project.nil?
    redirect_to project_path(@project.to_param), :status => :moved_permanently if params[:platform] != params[:platform].downcase || params[:name] != @project.name
    @color = @project.color
  end
end
