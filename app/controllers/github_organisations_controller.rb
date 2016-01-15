class GithubOrganisationsController < ApplicationController
  def index
    @most_repos = GithubOrganisation.most_repos.limit(20).to_a
    @most_stars = GithubOrganisation.most_stars.limit(20).to_a
    @newest = GithubOrganisation.newest.limit(20).to_a
  end

  def mozilla
    @org_logins = ['mozilla', 'mozilla-it', 'bugzilla', 'drumbeat-badge-sprint', 'hackasaurus', 'jetpack-labs', 'mdn', 'mozbrick', 'mozilla-appmaker', 'mozilla-b2g', 'mozilla-comm', 'mozilla-cordova', 'mozilla-metrics', 'mozilla-raptor', 'mozilla-services', 'mozilla-svcops', 'mozillatw', 'Mozilla-TWQA', 'mozillahispano', 'MozillaSecurity', 'MozillaWiki', 'mozillayvr', 'mozfr', 'OpenNews', 'rust-lang', 'servo', 'tabulapdf', 'webcompat', 'mozilla-l10n']
    @orgs = GithubOrganisation.where(login: @org_logins).includes(:source_github_repositories).sort_by{|o| -o.source_github_repositories.length }
    @repositories = GithubRepository.maintained.open_source.source.where(github_organisation_id: @orgs.map(&:id)).includes(:dependencies)
    @licenses = @repositories.group('license').count
    @languages = @repositories.group('language').count

    @dependencies = @repositories.map(&:dependencies).flatten
    project_ids = @dependencies.group_by(&:project_id).sort_by { |id, deps| -deps.length }.map(&:first).compact.first(10)
    @projects = Project.where(id: project_ids).order("position(','||projects.id::text||',' in '#{project_ids.join(',')}'), rank DESC")
  end
end
