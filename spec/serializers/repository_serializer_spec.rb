# frozen_string_literal: true

require "rails_helper"

describe RepositorySerializer do
  subject { described_class.new(build(:repository)) }

  it "should have expected attribute names" do
    expect(subject.attributes.keys).to eql(%i[
      full_name description fork created_at updated_at
      pushed_at homepage size stargazers_count language
      has_issues has_wiki has_pages forks_count mirror_url
      open_issues_count default_branch subscribers_count uuid
      source_name license private contributions_count has_readme
      has_changelog has_contributing has_license has_coc
      has_threat_model has_audit status last_synced_at rank
      host_type host_domain name scm fork_policy github_id
      pull_requests_enabled logo_url github_contributions_count keywords
    ])
  end

  context "when :include_readme option is true" do
    subject { described_class.new(build(:repository, readme: build(:readme, html_body: "<html>this is my readme</html>")), include_readme: true) }

    it "renders readme when flag is passed" do
      expect(subject.attributes.keys).to include(:readme_html_body)
      expect(subject.readme_html_body).to eq("<html>this is my readme</html>")
    end
  end
end
