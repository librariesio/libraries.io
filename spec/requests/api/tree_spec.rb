# frozen_string_literal: true

require "rails_helper"

describe "Api::TreesController" do
  let!(:old_version) { create(:version, number: "1.0.0", published_at: 1.month.ago) }
  let!(:new_version) { create(:version, number: "2.0.0", project: old_version.project, published_at: 1.day.ago) }
  let(:user) { create(:user) }

  describe "GET /api/:platform/:name/tree", type: :request do
    it "renders successfully" do
      get "/api/#{new_version.project.platform}/#{new_version.project.name}/tree?api_key=#{user.api_key}"
      expect(response).to have_http_status(:success)
      expect(response.content_type).to start_with("application/json")
      expect(response.body).to be_json_eql TreeResolver.new(new_version, "runtime", Date.today).tree.to_json
    end
  end

  describe "GET /api/:platform/:name/:number/tree", type: :request do
    it "renders successfully" do
      get "/api/#{old_version.project.platform}/#{old_version.project.name}/#{old_version.number}/tree?api_key=#{user.api_key}"
      expect(response).to have_http_status(:success)
      expect(response.content_type).to start_with("application/json")
      expect(response.body).to be_json_eql TreeResolver.new(old_version, "runtime", Date.today).tree.to_json
    end
  end
end
