class SourceRankCalculator
  def initialize(project)
    @project = project
  end

  def overall_score
    total_score/3.0
  end

  def popularity_score
    0
  end

  def community_score
    0
  end

  def quality_score
    0
  end

  private

  def total_score
    popularity_score + community_score + quality_score
  end
end
