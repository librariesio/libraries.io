require "rails_helper"

describe "RepositoryTreeController", :vcr do
  let(:repository) { create(:repository) }

  describe "GET /:platform/:project/tree", type: :request do
    it "renders successfully when logged out" do
      visit repository_tree_path(repository.owner_name, repository.project_name)
      expect(page).to have_content 'Dependency Tree'
    end
  end
end
