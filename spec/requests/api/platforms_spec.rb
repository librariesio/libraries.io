require "rails_helper"

describe "Api::PlatformsController", elasticsearch: true do
  describe "GET /api/platforms", type: :request do
    it "renders successfully" do
      create(:project)
      Project.__elasticsearch__.refresh_index!
      get '/api/platforms'
      expect(response).to have_http_status(:success)
      expect(response.content_type).to eq('application/json')
      expect(json).to eq [{
        "name"=>"Rubygems",
        "project_count"=>1,
        "homepage"=>"https://rubygems.org",
        "color"=>"#701516",
        "default_language"=>"Ruby"
      }]
    end
  end
end
