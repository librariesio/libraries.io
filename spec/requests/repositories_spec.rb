# frozen_string_literal: true

require "rails_helper"

describe "RepositoriesController" do
  shared_examples "repo redirect" do |fetch_url, redirect_target_url|
    it "redirects to the repo host" do
      get fetch_url
      expect(response.status).to eq 301
      expect(response.location).to eq redirect_target_url
    end
  end

  it_behaves_like "repo redirect", "/github/rails/rails", "https://github.com/rails/rails"
  it_behaves_like "repo redirect", "/github/rails/rails/tags", "https://github.com/rails/rails"
  it_behaves_like "repo redirect", "/github/rails/rails/contributors", "https://github.com/rails/rails"
  it_behaves_like "repo redirect", "/github/rails/rails/forks", "https://github.com/rails/rails"
  it_behaves_like "repo redirect", "/bitbucket/rails/rails", "https://bitbucket.com/rails/rails"
  it_behaves_like "repo redirect", "/gitlab/rails/rails", "https://gitlab.com/rails/rails"
end
