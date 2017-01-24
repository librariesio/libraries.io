class Api::StatusController < Api::ApplicationController
  before_action :require_api_key

  def check
    if params[:projects].any?
      @projects = params[:projects].group_by{|project| project[:platform] }.map do |platform, projects|
        Project.lookup_multiple(find_platform_by_name(platform), projects.map{|project| project[:name] }).paginate(page: 1, per_page: 1000).records.includes(:repository, :versions)
      end.flatten.compact
    else
      @projects = []
    end
    render json: project_json_response(@projects)
  end

  private

  def find_platform_by_name(name)
    PackageManager::Base.platforms.find{|p| p.to_s.demodulize.downcase == name.downcase }.try(:to_s).try(:demodulize)
  end
end
