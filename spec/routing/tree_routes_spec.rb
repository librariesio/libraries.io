require "rails_helper"

describe "tree routes", :type => :routing do
  it 'routes npm modules correctly' do
    expect(:get => "/npm/webpack/4.4.1/tree").to route_to(
      :controller => "tree",
      :action => "show",
      :platform => "npm",
      :name => "webpack",
      :number => "4.4.1"
    )
  end

  it 'routes npm modules with slashes correctly' do
    expect(:get => "/npm/@babel%2Fcore/7.0.0-beta.44/tree").to route_to(
      :controller => "tree",
      :action => "show",
      :platform => "npm",
      :name => "@babel/core",
      :number => "7.0.0-beta.44"
    )
  end
end
