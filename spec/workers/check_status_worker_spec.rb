# frozen_string_literal: true

require "rails_helper"

describe CheckStatusWorker do
  it "should use the low priority queue" do
    is_expected.to be_processed_in :status
  end

  it "should check repo status" do
    uri_ignoring_trailing_id = lambda do |request1, request2|
      uri1 = request1.uri
      uri2 = request2.uri
      # capture all versions matching "rails" with sequence
      regexp_trail_id = /rails\d+.json/
      if uri1.match(regexp_trail_id)
        r1_without_id = uri1.gsub(regexp_trail_id, "")
        r2_without_id = uri2.gsub(regexp_trail_id, "")
        uri1.match(regexp_trail_id) && uri2.match(regexp_trail_id) && r1_without_id == r2_without_id
      else
        uri1 == uri2
      end
    end

    VCR.use_cassette("project/check_status/rails", match_requests_on: [:method, uri_ignoring_trailing_id]) do
      project = create(:project)
      expect(Project).to receive(:find_by_id).with(project.id).and_return(project)
      subject.perform(project.id)
    end
  end
end
