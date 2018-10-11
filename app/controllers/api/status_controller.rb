class Api::StatusController < Api::ApplicationController
  before_action :require_api_key

  def check
    if params[:projects].any?
      # Try to get all the projects passed in.
      @projects = params[:projects].group_by{|project| project[:platform] }.map do |platform, projects|
        projects.each_slice(1000).map do |slice|
          Project.platform(platform).where(name: slice.map{|project| project[:name] }.uniq).includes(:repository, :versions)
        end
      end.flatten.compact

      # If there are any that don't get found, downcase them and try again
      if params[:projects].length != @projects.length

        # downcase all platform/name pairs we've found so we can match against them later
        found = @projects.map { |project| [project[:platform].downcase, project[:name].downcase] }
        # Find any projects that were passed that we didn't find, to try them again but case insensitive
        missing = params[:projects].select { |project| !found.include?([project[:platform].downcase, project[:name].downcase]) }

        lowercase_project_named = missing.group_by{|project| project[:platform] }.map do |platform, projects|
          projects.each_slice(1000).map do |slice|
            downcased_names = slice.map {|project| project[:name].downcase }
            # Filter by platform and lowercase compare the downcased_names
            Project.platform(platform).where('lower(name) in (?)', downcased_names).includes(:repository, :versions)
          end
        end.flatten.compact
        # Concatanate any new items found.
        @projects.concat(lowercase_project_named)
      end
    else
      @projects = []
    end
    fields = Project::API_FIELDS
    if params[:score]
      fields.push :score
    end
    render json: @projects.to_json({
      only: fields,
      methods: [:package_manager_url, :stars, :forks, :keywords, :latest_stable_release, :latest_download_url],
      include: {
        versions: {
          only: [:number, :published_at]
        }
      }
    })
  end
end
