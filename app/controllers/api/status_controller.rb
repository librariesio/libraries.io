class Api::StatusController < Api::ApplicationController
  before_action :require_api_key

  def check
    if params[:projects].any?
      @projects = params[:projects].group_by{|project| project[:platform] }.map do |platform, projects|
        projects.each_slice(1000).map do |slice|
          Project.platform(platform).where(name: slice.map{|project| project[:name] }.uniq).includes(:repository, :versions)
        end.flatten.compact
      end.flatten.compact
    else
      @projects = []
    end
    render json: @projects.to_json({
      only: Project::API_FIELDS,
      methods: [:package_manager_url, :stars, :forks, :keywords, :latest_stable_release, :latest_download_url],
      include: {
        versions: {
          only: [:number, :published_at]
        }
      }
    })
  end
end
