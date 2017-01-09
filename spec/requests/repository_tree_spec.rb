require "rails_helper"

describe "RepositoryTreeController", :vcr do
  let(:github_repository) { create(:github_repository) }

  describe "GET /:platform/:project/tree", type: :request do
    it "renders successfully when logged out" do
      visit github_repository_tree_path(github_repository.owner_name, github_repository.project_name)
      expect(page).to have_content 'Dependency Tree'
    end
  end
end
