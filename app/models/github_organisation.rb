class GithubOrganisation < ActiveRecord::Base
  API_FIELDS = [:name, :login, :blog, :email, :location, :description]

  has_many :github_repositories

  def github_contributions
    GithubContribution.none
  end

  def favourite_projects
    Project.none
  end

  def avatar_url(size = 60)
    "https://avatars.githubusercontent.com/u/#{github_id}?size=#{size}"
  end

  def github_url
    "https://github.com/#{login}"
  end

  def to_s
    name.presence || login
  end

  def to_param
    login
  end

  def company
    nil
  end

  def self.create_from_github(login_or_id)
    begin
      r = AuthToken.client.org(login_or_id).to_hash
      return false if r.blank?
      g = GithubOrganisation.find_or_initialize_by(github_id: r[:id])
      g.github_id = r[:id]
      g.assign_attributes r.slice(*GithubOrganisation::API_FIELDS)
      g.save
      g
    rescue Octokit::RepositoryUnavailable, Octokit::NotFound, Octokit::Forbidden, Octokit::InternalServerError, Octokit::BadGateway => e
      p e
      false
    end
  end
end
