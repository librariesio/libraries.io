require "rails_helper"

describe "HooksController" do
  describe "POST /priority/:platform/:name/:priority", type: :request do
    let!(:project) { create(:project, name: "rails") }
    let!(:api_key_internal) { create(:api_key, is_internal: true) }
    let!(:api_key_external) { create(:api_key) }

    it "403s without api key" do
      post "/api/priority/rubygems/rails/low"
      expect(response).to have_http_status(:forbidden)
    end

    it "403s without external api key" do
      post "/api/priority/rubygems/rails/low?api_key=#{api_key_external.access_token}"
      expect(response).to have_http_status(:forbidden)
    end

    it "404s with internal api key and non-existent project" do
      post "/api/priority/fake/rails/low?api_key=#{api_key_internal.access_token}"
      expect(response).to have_http_status(:not_found)
    end

    it "400s with bad priority" do
      post "/api/priority/rubygems/rails/fake?api_key=#{api_key_internal.access_token}"
      expect(response).to have_http_status(:bad_request)
    end

    it "successfully creates a priority object with a valid request" do
      post "/api/priority/rubygems/rails/low?api_key=#{api_key_internal.access_token}"
      expect(response).to have_http_status(:ok)
      expect(ProjectUpdatePriority.find_by_project_id(project.id).low?).to be true
    end
  end
end
