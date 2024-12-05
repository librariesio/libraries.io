# frozen_string_literal: true

require "rails_helper"

describe "UsersController" do
  shared_examples "repo user redirect" do |fetch_url, redirect_target_url|
    it "redirects to the repo host" do
      get fetch_url
      expect(response.status).to eq 301
      expect(response.location).to eq redirect_target_url
    end
  end

  it_behaves_like "repo user redirect", "/github/rails", "https://github.com/rails"
  it_behaves_like "repo user redirect", "/bitbucket/rails", "https://bitbucket.com/rails"
  it_behaves_like "repo user redirect", "/gitlab/rails", "https://gitlab.com/rails"
end
