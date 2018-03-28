require 'rails_helper'

describe SourceRankCalculator do
  let(:project) { build(:project) }
  let(:calculator) { SourceRankCalculator.new(project) }

  describe "#overall_score" do
    it "should be the average of all category scores" do
      allow(calculator).to receive(:popularity_score) { 10 }
      allow(calculator).to receive(:community_score) { 20 }
      allow(calculator).to receive(:quality_score) { 30 }

      expect(calculator.overall_score).to eq(20)
    end
  end

  describe '#basic_info_score' do
    let(:repository) { create(:repository) }
    let!(:readme) { create(:readme, repository: repository) }

    context "if all basic info fields are present" do
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

    context "if none of the basic info fields are present" do
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

  describe '#contribution_docs_score' do
    let!(:project) { build(:project, repository: repository) }

    context "if all contribution docs are present" do
      let(:repository) { create(:repository, has_coc: 'CODE_OF_CONDUCT',
                                             has_contributing: 'contributing.md',
                                             has_changelog: 'changelog.md') }
      it "should be 100" do
        expect(calculator.contribution_docs_score).to eq(100)
      end
    end

    context "if none of the contribution docs are present" do
      let(:repository) { create(:repository, has_coc: '',
                                             has_contributing: nil,
                                             has_changelog: '') }
      it "should be 0" do
        expect(calculator.contribution_docs_score).to eq(0)
      end
    end
  end

  describe '#dependent_projects_score' do
    context "if it has the highest number of dependent projects in its ecosystem" do
      it "should be 100" do
        allow(project).to receive(:dependents_count) { 999 }
        allow(calculator).to receive(:max_dependent_projects) { 999 }

        expect(calculator.dependent_projects_score).to eq(100)
      end
    end

    context "if it doesn't have the highest number of dependent projects in its ecosystem" do
      it "should be a percentage of the highest" do
        allow(project).to receive(:dependents_count) { 50 }
        allow(calculator).to receive(:max_dependent_projects) { 100 }

        expect(calculator.dependent_projects_score).to eq(50)
      end
    end
  end

  describe '#dependent_repos_count' do
    context "if it has the highest number of dependent projects in its ecosystem" do
      it "should be 100" do
        allow(project).to receive(:dependent_repos_count) { 999 }
        allow(calculator).to receive(:max_dependent_repositories) { 999 }

        expect(calculator.dependent_repositories_score).to eq(100)
      end
    end

    context "if it doesn't have the highest number of dependent projects in its ecosystem" do
      it "should be a percentage of the highest" do
        allow(project).to receive(:dependent_repos_count) { 50 }
        allow(calculator).to receive(:max_dependent_repositories) { 100 }

        expect(calculator.dependent_repositories_score).to eq(50)
      end
    end
  end

  describe '#stars_score' do
    context "if it has the highest number of stars in its ecosystem" do
      it "should be 100" do
        allow(project).to receive(:stars) { 19000 }
        allow(calculator).to receive(:max_stars) { 19000 }

        expect(calculator.stars_score).to eq(100)
      end
    end

    context "if it doesn't have the highest number of stars in its ecosystem" do
      it "should be a percentage of the highest" do
        allow(project).to receive(:stars) { 19 }
        allow(calculator).to receive(:max_stars) { 19000 }

        expect(calculator.stars_score).to eq(0.1)
      end
    end
  end

  describe '#forks_score' do
    context "if it has the highest number of forks in its ecosystem" do
      it "should be 100" do
        allow(project).to receive(:forks) { 56 }
        allow(calculator).to receive(:max_forks) { 56 }

        expect(calculator.forks_score).to eq(100)
      end
    end

    context "if it doesn't have the highest number of forks in its ecosystem" do
      it "should be a percentage of the highest" do
        allow(project).to receive(:forks) { 1 }
        allow(calculator).to receive(:max_forks) { 10 }

        expect(calculator.forks_score).to eq(10)
      end
    end
  end

  describe '#popularity_score' do
    it "should be the average of popularity category scores" do
      allow(calculator).to receive(:dependent_repositories_score) { 90 }
      allow(calculator).to receive(:dependent_projects_score) { 20 }
      allow(calculator).to receive(:stars_score) { 55 }
      allow(calculator).to receive(:forks_score) { 70 }
      allow(calculator).to receive(:watchers_score) { 10 }

      expect(calculator.popularity_score).to eq(49)
    end
  end

  describe '#quality_score' do
    it "should be the average of quality category scores" do
      allow(calculator).to receive(:basic_info_score) { 100 }
      allow(calculator).to receive(:status_score) { 0 }

      expect(calculator.quality_score).to eq(50)
    end
  end
end
