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
    render json: @projects.as_json({
      only: Project::API_FIELDS,
      methods: [:package_manager_url, :stars, :forks, :keywords, :latest_stable_release],
      include: {
        versions: {
          only: [:number, :published_at]
        }
      }
    })
  end

  private

  def find_platform_by_name(name)
    PackageManager::Base.platforms.find{|p| p.to_s.demodulize.downcase == name.downcase }.try(:to_s).try(:demodulize)
  end
end
