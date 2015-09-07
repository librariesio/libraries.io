class GithubOrganisationsController < ApplicationController
  def index
    @most_repos = GithubOrganisation.most_repos.limit(15).to_a
    @most_stars = GithubOrganisation.most_stars.limit(15).to_a
    @newest = GithubOrganisation.newest.limit(15).to_a
  end
end
