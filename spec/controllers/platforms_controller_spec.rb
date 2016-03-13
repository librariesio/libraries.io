require "rails_helper"

RSpec.describe PlatformsController, elasticsearch: true do
  let(:project) { create(:project) }

  before :all do
    Project.__elasticsearch__.create_index! index: Project.index_name
  end

  after :all do
    Project.__elasticsearch__.client.indices.delete index: Project.index_name
  end

  describe "GET #index" do
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
