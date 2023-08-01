# frozen_string_literal: true

require "rails_helper"

describe FetchLiftedProjects do
  describe "#run" do
    subject { FetchLiftedProjects.new }

    let(:base_url) { "https://api.tidelift.com/external-api/packages?lifted=true" }
    let(:projects) { create_list(:project, 101) }

    before do
      allow(Rails.configuration).to receive(:tidelift_api_key).and_return("asdfasdf")
    end

    it "without a Tidelift api key" do
      allow(Rails.configuration).to receive(:tidelift_api_key).and_return(nil)
      expect { subject.run }.to raise_error(FetchLiftedProjects::MissingApiKey)
    end

    it "fetches and paginates over list of lifted packages" do
      WebMock.stub_request(:get, "https://api.tidelift.com/external-api/packages?lifted=true&page=1&per_page=100")
        .to_return(body: JSON.dump({
                                     "current_page" => 1,
                                     "next_page" => 2,
                                     "prev_page" => nil,
                                     "total_pages" => 2,
                                     "total_count" => 101,
                                     "results" => projects[0, 100].map { |p| { "platform" => p.platform.downcase, "name" => p.name } },
                                   }))
      WebMock.stub_request(:get, "https://api.tidelift.com/external-api/packages?lifted=true&page=2&per_page=100")
        .to_return(body: JSON.dump({
                                     "current_page" => 2,
                                     "next_page" => nil,
                                     "prev_page" => 1,
                                     "total_pages" => 2,
                                     "total_count" => 101,
                                     "results" => projects[100, 1].map { |p| { "platform" => p.platform.downcase, "name" => p.name } },
                                   }))

      expect(subject.run).to match_array(projects)
    end

    it "raises an error if it receives a bad response" do
      WebMock.stub_request(:get, "https://api.tidelift.com/external-api/packages?lifted=true&page=1&per_page=100").to_return(status: 500)

      expect { subject.run }.to raise_error(FetchLiftedProjects::BadResponse) { |e|
        expect(e.message).to eq("FetchLiftedProjects received a 500 code on page 1")
      }
    end
  end
end
