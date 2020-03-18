# frozen_string_literal: true

class RepositoryOrganisationsController < ApplicationController
  def index
    @most_repos = RepositoryOrganisation.visible.most_repos.limit(20).to_a
    @most_stars = RepositoryOrganisation.visible.most_stars.limit(20).to_a
    @newest = RepositoryOrganisation.visible.newest.limit(20).to_a
  end
end
