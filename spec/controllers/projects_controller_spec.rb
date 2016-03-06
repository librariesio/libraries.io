require "rails_helper"

RSpec.describe ProjectsController, elasticsearch: true do
  describe "GET #index" do
    before do
      Project.__elasticsearch__.create_index! index: Project.index_name

      create(:project)
      sleep 1
    end

    after do
      Project.__elasticsearch__.client.indices.delete index: Project.index_name
    end

    it "responds successfully with an HTTP 200 status code" do
      get :index
      expect(response).to be_success
      expect(response).to have_http_status(200)
    end

    it "renders the index template" do
      get :index
      expect(response).to render_template("index")
    end
  end
end
