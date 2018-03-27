require 'rails_helper'

describe SourceRankCalculator do
  let!(:project) { create(:project) }
  let(:calculator) { SourceRankCalculator.new(project) }

  describe "#overall_score" do
    it "should be the average of three category scores" do
      allow(calculator).to receive(:popularity_score) { 10 }
      allow(calculator).to receive(:community_score) { 20 }
      allow(calculator).to receive(:quality_score) { 30 }

      expect(calculator.overall_score).to eq(20)
    end
  end
end
