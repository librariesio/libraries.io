require "rails_helper"

describe "HooksController" do
  describe "POST /hooks/github", type: :request do
    it "renders successfully" do
      post "/hooks/github",
        params: {repository: {id: 1}, sender: {id: 1}},
        headers: { "X-GitHub-Event" => "push" }

      expect(response).to have_http_status(:success)
    end
  end
end
