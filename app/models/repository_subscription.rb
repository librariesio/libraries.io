class RepositorySubscription < ActiveRecord::Base
  belongs_to :user
  belongs_to :github_repository
  has_many :subscriptions

  def update_subscriptions
    projects = []
    github_repository.repository_dependencies.each do |dep|
      if dep.project.present?
        project = dep.project.try(:id)
      else
        project = Project.platform(dep.platform).where('lower(name) = ?', dep.project_name.downcase).first.try(:id)
      end
      projects << project
    end
    projects.compact!

    existing = subscriptions.map(&:project_id)

    subscriptions.where(project_id: (existing - projects)).delete_all
    (projects - existing).each do |project_id|
      subscriptions.create(project_id: project_id)
    end
  end
end
