class PagesController < ApplicationController
  def about

  end

  def team

  end

  def privacy

  end

  def compatibility

  end

  def experiments
    @platforms = Project.popular_platforms(:facet_limit => 40).first(28)

  end

  def data
    @platforms = Project.popular_platforms(:facet_limit => 40).first(28)

  end
end
