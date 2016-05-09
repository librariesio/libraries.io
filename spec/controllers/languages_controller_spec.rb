require "rails_helper"

RSpec.describe LanguagesController, elasticsearch: true do
  let(:project) { create(:project) }

  before :each do
    Project.__elasticsearch__.create_index! index: Project.index_name
  end

  after :each do
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

  describe "GET #show" do
    it "responds successfully with an HTTP 200 status code" do
      get :show, params: { id: project.language }
      expect(response).to be_success
      expect(response).to have_http_status(200)
    end

    it "renders the show template" do
      get :show, params: { id: project.language }
      expect(response).to render_template("show")
    end
  end
end
