require "rails_helper"

describe "Api::IssuesController", elasticsearch: true do
  let!(:issue) { create(:issue) }

  describe "GET /api/github/issues/help-wanted", type: :request do
    it "renders successfully" do
      Issue.__elasticsearch__.refresh_index!
      get '/api/github/issues/help-wanted'
      expect(response).to have_http_status(:success)
      expect(response.content_type).to eq('application/json')
      expect(json).to eq([{
        "number": issue.number,
        "state": issue.state,
        "title": issue.title,
        "body": issue.body,
        "locked": issue.locked,
        "closed_at": issue.closed_at,
        "created_at": issue.created_at,
        "updated_at": issue.updated_at,
        "uuid": issue.uuid,
        "host_type": issue.host_type,
        "repository": RepositorySerializer.new(issue.repository).to_hash
      }].as_json)
    end
  end

  describe "GET /api/github/issues/first-pull-request", type: :request do
    it "renders successfully" do
      Issue.__elasticsearch__.refresh_index!
      get '/api/github/issues/first-pull-request'
      expect(response).to have_http_status(:success)
      expect(response.content_type).to eq('application/json')
      expect(json).to eq([{
        "number": issue.number,
        "state": issue.state,
        "title": issue.title,
        "body": issue.body,
        "locked": issue.locked,
        "closed_at": issue.closed_at,
        "created_at": issue.created_at,
        "updated_at": issue.updated_at,
        "uuid": issue.uuid,
        "host_type": issue.host_type,
        "repository": RepositorySerializer.new(issue.repository).to_hash
      }].as_json)
    end
  end
end
