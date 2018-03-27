require 'rails_helper'

describe SourceRankCalculator do
  let(:project) { build(:project) }
  let(:calculator) { SourceRankCalculator.new(project) }

  describe "#overall_score" do
    it "should be the average of three category scores" do
      allow(calculator).to receive(:popularity_score) { 10 }
      allow(calculator).to receive(:community_score) { 20 }
      allow(calculator).to receive(:quality_score) { 30 }

      expect(calculator.overall_score).to eq(20)
    end
  end

  describe '#basic_info_score' do
    let(:repository) { create(:repository) }
    let!(:readme) { create(:readme, repository: repository) }

    context "if all four basic info fields are present" do
      let!(:project) { build(:project, repository: repository,
                                       description: 'project description',
                                       homepage: 'http://homepage.com',
                                       repository_url: 'https://github.com/foo/bar',
                                       keywords_array: ['foo', 'bar', 'baz'],
                                       normalized_licenses: ['MIT']) }
      it "should be 100" do
        expect(calculator.basic_info_score).to eq(100)
      end
    end

    context "if none of four basic info fields are present" do
      let!(:project) { build(:project, description: '',
                                        homepage: '',
                                        repository_url: '',
                                        keywords_array: [],
                                        normalized_licenses: []) }
      it "should be 0" do
        expect(calculator.basic_info_score).to eq(0)
      end
    end
  end
end
