namespace :transitive do
  task mozilla: :environment do
    @org_logins = ['mozilla', 'mozilla-it', 'bugzilla', 'drumbeat-badge-sprint', 'hackasaurus', 'jetpack-labs', 'mdn', 'mozbrick', 'mozilla-appmaker', 'mozilla-b2g', 'mozilla-comm', 'mozilla-cordova', 'mozilla-metrics', 'mozilla-raptor', 'mozilla-services', 'mozilla-svcops', 'mozillatw', 'Mozilla-TWQA', 'mozillahispano', 'MozillaSecurity', 'MozillaWiki', 'mozillayvr', 'mozfr', 'OpenNews', 'rust-lang', 'servo', 'tabulapdf', 'webcompat']
    @orgs = GithubOrganisation.where(login: @org_logins).includes(:source_github_repositories).sort_by{|o| -o.source_github_repositories.length }
    @repositories = GithubRepository.open_source.source.where(github_organisation_id: @orgs.map(&:id))
    # @repositories = [GithubRepository.find_by_full_name('24pullrequests/24pullrequests')]
    deps = @repositories.map(&:repository_dependencies).flatten

    dep_counts = {}
    dep_tree = {}

    deps.each do |dep|
      puts '*'*20
      dep_name = [dep.platform.downcase, dep.project_name.downcase].join('/')

      if dep_counts[dep_name]
        dep_counts[dep_name] += 1
        next_deps = []
      else
        dep_counts[dep_name] = 1
        next_deps = get_dependencies(dep.project)
      end

      while next_deps.length > 0
        puts '*'*20
        dep_collector = []
        next_deps.each do |d|
          dep_name = [d.platform.downcase, d.project_name.downcase].join('/')
          if dep_counts[dep_name]
            dep_counts[dep_name] += 1
          else
            dep_counts[dep_name] = 1
            dep_collector << get_dependencies(d.project)
          end
        end
        next_deps = dep_collector.flatten
      end
    end

    pp dep_counts.sort_by{|k,v| -v};nil
  end
end

def get_dependencies(project)
  return [] unless project
  latest_version = project.latest_version
  return [] unless latest_version
  latest_version.dependencies.where(kind: 'normal')
end
