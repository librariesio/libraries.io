# frozen_string_literal: true

require "rails_helper"

describe "RepositoryTreeController" do
  let(:repository) { create(:repository) }

  describe "GET /:platform/:project/tree", type: :request do
    it "renders successfully when logged out" do
      visit repository_tree_path(repository.to_param)
      expect(page).to have_content "Dependency Tree"
    end
  end
end
