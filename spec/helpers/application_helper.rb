# frozen_string_literal: true

require "rails_helper"

describe ApplicationHelper do
  describe "#colours" do
    it "returns an array" do
      expect(helper.colours).to be_a(Array)
    end
  end

  describe "#sort_options" do
    it "returns an array" do
      expect(helper.sort_options).to be_a(Array)
    end
  end

  describe "#repo_sort_options" do
    it "returns an array" do
      expect(helper.repo_sort_options).to be_a(Array)
    end
  end

  describe "#shareable_image_url" do
    it "returns a url" do
      expect(helper.shareable_image_url("Rubygems")).to eq("https://librariesio.github.io/pictogram/rubygems/rubygems.png")
    end
  end
end
