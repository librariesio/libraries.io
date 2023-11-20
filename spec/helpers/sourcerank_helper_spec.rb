# frozen_string_literal: true

require "rails_helper"

describe SourcerankHelper do
  describe "#source_rank_badge_class" do
    it "returns 'alert-success' for value > 0" do
      expect(helper.source_rank_badge_class(1)).to eq("alert-success")
    end

    it "returns 'alert-danger' for value < 0" do
      expect(helper.source_rank_badge_class(-1)).to eq("alert-danger")
    end

    it "returns 'alert-warning' for value == 0" do
      expect(helper.source_rank_badge_class(0)).to eq("alert-warning")
    end
  end

  describe "#source_rank_titles" do
    it "returns a hash" do
      expect(helper.source_rank_titles).to be_a(Hash)
    end
  end

  describe "#source_rank_explainations" do
    it "returns a hash" do
      expect(helper.source_rank_explainations).to be_a(Hash)
    end
  end

  describe "#negative_factors" do
    it "returns a hash" do
      expect(helper.negative_factors).to be_a(Array)
    end
  end

  describe "#skip_showing_if_zero?" do
    it "returns false for positive factors" do
      expect(helper.skip_showing_if_zero?(:subscribers, 1)).to be_falsey
    end

    it "returns true if value is zero" do
      expect(helper.skip_showing_if_zero?(:is_removed, 0)).to be_truthy
    end

    it "returns true if key is a negative_factor and value is not zero" do
      expect(helper.skip_showing_if_zero?(:is_removed, -1)).to be_falsey
    end
  end
end
