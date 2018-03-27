require 'rails_helper'

describe SourceRankCalculator do
  let!(:project) { create(:project) }
  let(:calculator) { SourceRankCalculator.new(project) }

  describe "#overall_score" do
    it "returns combined sourcerank 2.0 score for a project" do
      expect(calculator.overall_score).to eq(0)
    end
  end
end
