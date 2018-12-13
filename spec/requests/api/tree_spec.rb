require "rails_helper"
describe "Api::TreesController" do
  let(:version) { create(:version) }
  let(:user) { create(:user) }

  describe "GET /api/:platform/:name/tree", type: :request do
    it "renders successfully" do
      get "/api/#{version.project.platform}/#{version.project.name}/tree?api_key=#{user.api_key}"
      expect(response).to have_http_status(:success)
      expect(response.content_type).to eq('application/json')

      version.reload
      expect(response.body).to be_json_eql TreeResolver.new(version, 'runtime', Date.today).tree.to_json
    end
  end
end
