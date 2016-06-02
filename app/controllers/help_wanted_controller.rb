class HelpWantedController < ApplicationController

  def index
    @search = GithubIssue.search('').paginate(page: page_number, per_page: per_page_number)
    @github_issues = @search.records
    @title = 'Help Wanted'
    respond_to do |format|
      format.html
      format.atom
    end
  end

end
