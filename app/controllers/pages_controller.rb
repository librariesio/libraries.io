class PagesController < ApplicationController
  def about

  end

  def team

  end

  def privacy

  end

  def compatibility

  end

  def data
    @platforms = Project.popular_platforms(:facet_limit => 40).first(28)

  end
  def terms
    
  end
  def terms
    
  end
end
