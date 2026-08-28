# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Projects versions Atom feed", type: :request do
  let!(:project) { create(:project, platform: "NPM", name: "example-package") }
  let!(:version1) { create(:version, project: project, number: "1.0.0", published_at: 2.days.ago) }
  let!(:version2) { create(:version, project: project, number: "1.1.0", published_at: 1.day.ago) }

  it "renders RFC3339 <published> once per entry" do
    visit project_versions_path(project.to_param.merge(format: :atom))

    # Find all <published> elements
    published_nodes = Nokogiri::XML(page.body).xpath("//xmlns:entry/xmlns:published")
    expect(published_nodes.length).to eq(2)

    # RFC3339 basic check: YYYY-MM-DDTHH:MM:SSZ
    rfc3339_regex = /\A\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}Z\z/
    published_nodes.each do |node|
      expect(node.text).to match(rfc3339_regex)
    end
  end
end
