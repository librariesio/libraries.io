class GithubOrganisationsController < ApplicationController
  def index
    @most_repos = GithubOrganisation.visible.most_repos.limit(20).to_a
    @most_stars = GithubOrganisation.visible.most_stars.limit(20).to_a
    @newest = GithubOrganisation.visible.newest.limit(20).to_a
  end
end
