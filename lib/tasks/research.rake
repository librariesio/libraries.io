namespace :research do
  desc 'civic tech dependency research'
  task civic_tech: :environment do
    org_names = ['mysociety',
    'DemocracyClub',
    'opennorth',
    'alphagov',
    'gds-operations',
    '18F',
    'ciudadanointeligente',
    'codeforamerica',
    'okfn',
    'MuckRock',
    'ushahidi',
    'datamade',
    'loomio',
    'wikimedia',
    'WorldBank-Transport',
    'open-contracting',
    'openaustralia',
    'planningalerts-scrapers',
    'delib']

    orgs = RepositoryOrganisation.where(login: org_names)

    repositories = orgs.map{|org| org.repositories.source.open_source }.flatten

    projects = repositories.map(&:dependency_projects).flatten.map {|project| "#{project.platform}/#{project.name}" }

    project_counts = projects.reduce (Hash.new(0)) {|counts, el| counts[el]+=1; counts}

    project_counts.select{|k,v| v > 1 }.sort_by{|k,v| -v}.each {|k,v| puts "#{k} (#{v})" };nil
  end

  desc 'How many contributions to cii deps did civic tech people make'
  task civic_tech_deps: :environment do
    org_names = ['mysociety',
    'DemocracyClub',
    'opennorth',
    'alphagov',
    'gds-operations',
    '18F',
    'ciudadanointeligente',
    'codeforamerica',
    'okfn',
    'MuckRock',
    'ushahidi',
    'datamade',
    'loomio',
    'wikimedia',
    'WorldBank-Transport',
    'open-contracting',
    'openaustralia',
    'planningalerts-scrapers',
    'delib']

    orgs = RepositoryOrganisation.where(login: org_names)

    repositories = orgs.map{|org| org.repositories.source.open_source }.flatten

    # civic tech repos
    repositories.sort_by(&:url).each{|r| puts r.url };nil


    civic_tech_contributor_ids = Contribution.where(repository_id: repositories.map(&:id)).group(:repository_user_id).count.keys

    dependencies = repositories.map(&:dependency_projects).flatten.uniq
    dependency_repos = Repository.where(id: dependencies.map(&:repository_id).compact.uniq);nil


    dep_contribs = dependency_repos.map do |dep|
      total_commits = Contribution.where(repository_id: dep.id).sum(:count)
      civic_commits = Contribution.where(repository_id: dep.id, repository_user_id: civic_tech_contributor_ids).sum(:count)
      {
        dependency: dep.url,
        total_commits: total_commits,
        civic_commits: civic_commits,
        percentage: civic_commits.to_f/total_commits*100
      }
    end

    total_commits = Contribution.where(repository_id: dependency_repos.map(&:id)).sum(:count) # 2,682,407
    total_committers = Contribution.where(repository_id: dependency_repos.map(&:id)).group(:repository_user_id).count.keys.length # 81187
    civic_commits = Contribution.where(repository_id: dependency_repos.map(&:id), repository_user_id: civic_tech_contributor_ids).sum(:count) # 410,625
    civic_committers = Contribution.where(repository_id: dependency_repos.map(&:id), repository_user_id: civic_tech_contributor_ids).group(:repository_user_id).count.keys.length # 2977
    civic_commits.to_f/total_commits*100

    # top 1000 cii projects
    cii_projects = Project.not_removed.order('dependent_repos_count DESC NULLS LAST').limit(1000)
    cii_projects.each {|project| puts "#{project.platform}/#{project.name} (#{project.dependent_repos_count})" };nil

    # civic tech contributors
    RepositoryUser.where(id: civic_tech_contributor_ids).order('login ASC').pluck(:login).each{|login| puts "https://github.com/"+login };nil

    # github-users-that-contributed-to-ct-dependencies
    civic_tech_dependnency_contributor_ids = Contribution.where(repository_id: dependency_repos.map(&:id)).group(:repository_user_id).count.keys
    RepositoryUser.where(id: civic_tech_dependnency_contributor_ids).order('login ASC').pluck(:login).each{|login| puts "https://github.com/"+login };nil

    # cii_projects_used_by_civic_tech

    cii_projects_used_by_civic_tech = dependencies.uniq & cii_projects
    cii_projects_used_by_civic_tech.sort_by(&:dependent_repos_count).reverse.each {|project| puts "#{project.platform}/#{project.name}" };nil

    # cii_projects_used_by_civic_tech with usage counts

    dependencies = repositories.map(&:dependency_projects).flatten

    cii_projects = Project.not_removed.order('dependent_repos_count DESC NULLS LAST').limit(1000)

    cii_project_ids = cii_projects.map(&:id)

    cii_deps = dependencies.select{|p| cii_project_ids.include?(p.id)}

    projects = cii_deps.map(&:id)

    project_counts = projects.reduce (Hash.new(0)) {|counts, el| counts[el]+=1; counts}

    project_counts.select{|k,v| v > 0 }.sort_by{|k,v| -v}.each {|k,v| project = Project.find(k); puts "#{project.platform}/#{project.name} (#{v})" };nil

    json = project_counts.select{|k,v| v > 0 }.sort_by{|k,v| -v}.map do |k,v|
      project = Project.find(k)
      {
        project_name: "#{project.platform}/#{project.name}",
        project_id: project.id,
        count: v
      }
    end.to_json

    # commits to civic tech repos

    total_commits = Contribution.where(repository_id: repositories.map(&:id)).sum(:count)



    # ct people who contributed to cii projects

    cii_repository_ids = Repository.where(id: cii_projects.map(&:repository_id).uniq).pluck(:id).uniq

    total_commits = Contribution.where(repository_id: cii_repository_ids).sum(:count) # 1,061,393
    cii_committers = Contribution.where(repository_id: cii_repository_ids).group(:repository_user_id).count.keys.length # 38,262
    civic_commits = Contribution.where(repository_id: cii_repository_ids, repository_user_id: civic_tech_contributor_ids).sum(:count) # 151415
    civic_committers = Contribution.where(repository_id: cii_repository_ids, repository_user_id: civic_tech_contributor_ids).group(:repository_user_id).count.keys.length # 1177
    civic_commits.to_f/total_commits*100 # 7.4%

    # cii commiters

    cii_committer_ids = Contribution.where(repository_id: cii_repository_ids).group(:repository_user_id).count.keys
    RepositoryUser.where(id: cii_committer_ids).order('login ASC').pluck(:login).each{|login| puts "https://github.com/"+login };nil

    # civic tech contributors who committed to cii projects

    crossover_ids = civic_tech_contributor_ids & cii_committer_ids
    RepositoryUser.where(id: cii_committer_ids).order('login ASC').pluck(:login).each{|login| puts "https://github.com/"+login };nil

    # cii deps with less than 100 stars (unseen infrastucture)
    unique_cii_deps = cii_deps.uniq
    unseen = unique_cii_deps.select{|project| project.stars < 100 rescue true } # 207
    unseen.sort_by(&:stars).reverse.each {|project| puts "#{project.platform}/#{project.name} (#{project.stars})" };nil

    json = unseen.sort_by(&:stars).reverse.map do |project|
      {
        project: "#{project.platform}/#{project.name}",
        project_id: project.id,
        stars: project.stars
      }
    end.to_json

    # cii deps with less than 6 contributors (bus factor)
    bus_factor = unique_cii_deps.select{|project| project.contributors.length < 6 } # 144
    bus_factor.sort_by{|project| project.contributors.length}.reverse.each {|project| puts "#{project.platform}/#{project.name} (#{project.contributors.length})" };nil

    json= bus_factor.sort_by{|project| project.repository.try(:open_issues_count) || 0}.map do |project|
      {
        project: "#{project.platform}/#{project.name}",
        project_id: project.id,
        contributors: project.contributors.length
      }
    end.to_json

    # bus_factor unseen intersection
    unseen_bus_factor_ids = unseen.map(&:id) & bus_factor.map(&:id) # 127
    Project.where(id:unseen_bus_factor_ids).sort_by(&:dependent_repos_count).reverse.each {|project| puts "#{project.platform}/#{project.name} (#{project.dependent_repos_count})" };nil

    json= Project.where(id:unseen_bus_factor_ids).sort_by(&:dependent_repos_count).reverse.map do |project|
      {
        project: "#{project.platform}/#{project.name}",
        project_id: project.id,
        dependent_repos_count: project.dependent_repos_count,
        contributors: project.contributors.length,
        stars: project.stars
      }
    end.to_json

    # high open issues
    open_issues = unique_cii_deps.select{|project| (project.repository.try(:open_issues_count) || 0) > 100  } # 165
    open_issues.sort_by{|project| project.repository.try(:open_issues_count) || 0}.reverse.each {|project| puts "#{project.platform}/#{project.name} (#{project.repository.try(:open_issues_count)})" };nil

    json= open_issues.sort_by{|project| project.repository.try(:open_issues_count) || 0}.map do |project|
      {
        project: "#{project.platform}/#{project.name}",
        project_id: project.id,
        open_issues_count: project.repository.try(:open_issues_count) || 0
      }
    end.to_json

    # breakdown of percentage commits to cii deps by civit tech peeps

    dep_contribs = cii_projects.map do |dep|
      total_commits = Contribution.where(repository_id: dep.repository_id).sum(:count)
      civic_commits = Contribution.where(repository_id: dep.repository_id, repository_user_id: civic_tech_contributor_ids).sum(:count)
      {
        dependency: "#{dep.platform}/#{dep.name}",
        dependent_repos_count: dep.dependent_repos_count,
        project_id: dep.id,
        total_commits: total_commits,
        civic_commits: civic_commits,
        percentage: civic_commits.to_f/total_commits*100
      }
    end

    pp dep_contribs.sort_by{|h| h[:percentage].nan? ? 0 : -h[:percentage] };nil

    puts dep_contribs.sort_by{|h| h[:percentage].nan? ? 0 : -h[:percentage] }.to_json

    # cii deps license breakdown

    cii_projects.group_by(&:normalize_licenses).sort_by{|k,v| -v.length }.each{|k,v| puts "#{k.join('/')} (#{v.length})" };nil

    # civic tech deps license breakdown

    dependencies.group_by(&:normalize_licenses).sort_by{|k,v| -v.length }.each{|k,v| puts "#{k.join('/')} (#{v.length})" };nil

    # civic tech repos with clashing dependencies

    repositories.each do |repo|
      next if repo.license.blank?
      dependencies = repo.dependencies.includes(:project)
      next if dependencies.empty?
      invalid = dependencies.select do |dep|
        dep.project && dep.project.normalize_licenses.present? && !dep.compatible_license?
      end.uniq{|d| d.project.id }
      if invalid.any?
        puts "#{repo.url} - #{repo.license}"
        invalid.each do |dep|
          next if dep.project.normalize_licenses.blank?
          puts "  #{dep.platform}/#{dep.project.name} - #{dep.project.normalize_licenses.join('/')}"
        end
      end
    end;nil

  end

  desc 'output csv of cii maintainers'
  task contributors: :environment do
    projects = Project.digital_infrastructure.order('projects.dependent_repos_count DESC').includes(:repository)

    projects.each do |project|
      puts "- #{project.platform}/#{project.name} - https://librares.io/#{project.platform}/#{project.name}"
      puts "  - #{project.repository.url}"
      total_commits = project.contributions.sum(:count)
      threshold = total_commits.to_f/20
      project.contributions.order('count DESC').limit(5).each do |contribution|
        next if contribution.count < threshold && contribution.count < 5
        puts "    - #{contribution.count} commits (#{(contribution.count.to_f/total_commits*100).round}%) #{contribution.repository_user.repository_url} #{contribution.repository_user.email} #{contribution.repository_user.location}"
      end
      puts ""
    end;nil

    output = CSV.generate do |csv|
    csv << ['Project',	'Repo',	'Commits', 'Percentage',	'Maintainer URI',	'Maintener email', 'Maintainer Location']

      projects.each do |project|
        total_commits = project.contributions.sum(:count)
        threshold = total_commits.to_f/20
        project.contributions.order('count DESC').limit(5).each do |contribution|
          next if contribution.count < threshold && contribution.count < 10

          csv << ["#{project.platform}/#{project.name}", project.repository.url, contribution.count, (contribution.count.to_f/total_commits*100).round, contribution.repository_user.repository_url, contribution.repository_user.email, contribution.repository_user.location]

        end

      end

    end;nil
    puts output
  end

  desc 'most active contributors to cii'
  task top_cii_contributors: :environment do
    projects = Project.digital_infrastructure.order('projects.dependent_repos_count DESC').includes(:repository)
    contributor_ids = Contribution.where(repository_id: projects.map(&:repository_id)).group(:repository_user_id).sum(:count)
    top_1percent = contributor_ids.select{|k,v| v > 499 }.map{|k,v| [RepositoryUser.find(k), v]}

    output = CSV.generate do |csv|
    csv << ['Name', 'CII commits', 'URI',	'email', 'company', 'Location']

    top_1percent.sort_by(&:last).reverse.each do |user, commits|

      csv << [user.login, commits, user.repository_url, user.email, user.company, user.location]

    end

    end;nil
    puts output
  end

  desc 'list dependencies org grouped by org'
  task org_grouped_cumulative_dependency_list: :environment do

    org_name = 'librariesio'
    host = 'github'
    platform = 'rubygems'
    org = RepositoryOrganisation.host(host).find_by_login(org_name)

    own_dependencies = org.dependencies.platform(platform).includes(project: :repository).select{|d| d.project.try(:repository).try(:full_name) && d.project.repository.full_name.split('/').first == org_name }.length

    total = org.dependencies.platform(platform).count - own_dependencies

    counts = org.favourite_projects.platform(platform).count

    groups = org.favourite_projects.platform(platform).includes(:repository).group_by{|pr| pr.try(:repository).try(:full_name).try(:split,'/').try(:first) }

    usage = []

    groups.each do |owner_name, projects|
      next if owner_name == org_name

      if owner_name.present? && projects.length > 1 # multirepo
        name = owner_name + '*'
        count = projects.map(&:id).sum{|id| counts[id] }

        usage << [name, count]
      else
        projects.each do |project|
          name = project.name
          count = counts[project.id]

          usage << [name, count]
        end
      end
    end;nil

    rows = []
    running_total = 0

    usage.sort_by(&:second).reverse.each do |dep|
      running_total += dep[1]
      percentage = (running_total/total.to_f*100).round
      rows << [dep[0], dep[1], running_total, percentage]
    end

    output = CSV.generate do |csv|
      csv << ['Project Name', 'Used by Repos', 'Running Total', 'Running Percentage']

      rows.each{|row| csv << row }
    end;nil
    puts output

  end
end
