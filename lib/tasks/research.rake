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
    'open-contracting']

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
    'open-contracting']

    orgs = RepositoryOrganisation.where(login: org_names)

    repositories = orgs.map{|org| org.repositories.source.open_source }.flatten

    civic_tech_contributor_ids = Contribution.where(repository_id: repositories.map(&:id)).group(:repository_user_id).count.keys

    dependencies = repositories.map(&:dependency_projects).flatten.uniq
    dependency_repos = Repository.where(id: dependencies.map(&:repository_id).compact.uniq)


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

    total_commits = Contribution.where(repository_id: dependency_repos.map(&:id)).sum(:count) # 2,424,027
    civic_commits = Contribution.where(repository_id: dependency_repos.map(&:id), repository_user_id: civic_tech_contributor_ids).sum(:count) # 326830
    civic_committers = Contribution.where(repository_id: dependency_repos.map(&:id), repository_user_id: civic_tech_contributor_ids).group(:repository_user_id).count.keys.length
    civic_commits.to_f/total_commits*100

    # civic tech
    civic_tech_dependnency_contributor_ids = Contribution.where(repository_id: dependency_repos.map(&:id)).group(:repository_user_id).count.keys
    RepositoryUser.where(id: civic_tech_dependnency_contributor_ids).order('login ASC').pluck(:login).each{|login| puts "https://github.com/"+login }

    # cii_projects_used_by_civic_tech

    cii_projects_used_by_civic_tech = dependencies & cii_projects

    # cii_projects_used_by_civic_tech with usage counts

    dependencies = repositories.map(&:dependency_projects).flatten

    cii_projects = Project.not_removed.order('dependent_repos_count DESC NULLS LAST').limit(1000)

    cii_project_ids = cii_projects.map(&:id)

    cii_deps = dependencies.select{|p| cii_project_ids.include?(p.id)}

    projects = cii_deps.map {|project| "#{project.platform}/#{project.name}" }

    project_counts = projects.reduce (Hash.new(0)) {|counts, el| counts[el]+=1; counts}

    project_counts.select{|k,v| v > 0 }.sort_by{|k,v| -v}.each {|k,v| puts "#{k} (#{v})" };nil

    # ct people who contributed to cii projects

    cii_repository_ids = Repository.where(id: cii_projects.map(&:repository_id).uniq).pluck(:id).uniq

    total_commits = Contribution.where(repository_id: cii_repository_ids).sum(:count) # 963,039
    cii_committers = Contribution.where(repository_id: cii_repository_ids).group(:repository_user_id).count.keys.length # 36135
    civic_commits = Contribution.where(repository_id: cii_repository_ids, repository_user_id: civic_tech_contributor_ids).sum(:count) # 81,029
    civic_committers = Contribution.where(repository_id: cii_repository_ids, repository_user_id: civic_tech_contributor_ids).group(:repository_user_id).count.keys.length # 876
    civic_commits.to_f/total_commits*100 # 8%

    # cii commiters

    cii_committer_ids = Contribution.where(repository_id: cii_repository_ids).group(:repository_user_id).count.keys
    RepositoryUser.where(id: cii_committer_ids).order('login ASC').pluck(:login).each{|login| puts "https://github.com/"+login }

    unique_cii_deps = cii_deps.uniq

    # cii deps with less than 100 stars (unseen infrastucture)
    unseen = unique_cii_deps.select{|project| project.stars < 100 rescue true } # 226
    unseen.sort_by(&:stars).reverse.each {|project| puts "#{project.platform}/#{project.name} (#{project.stars})" };nil

    # cii deps with less than 6 contributors (bus factor)
    bus_factor = unique_cii_deps.select{|project| project.contributors.length < 6 } # 172
    bus_factor.sort_by{|project| project.contributors.length}.reverse.each {|project| puts "#{project.platform}/#{project.name} (#{project.contributors.length})" };nil

    # bus_factor unseen intersection
    unseen_bus_factor_ids = unseen.map(&:id) & bus_factor.map(&:id) # 153

    # high open issues
    open_issues = unique_cii_deps.select{|project| (project.repository.try(:open_issues_count) || 0) > 100  } # 27
    open_issues.sort_by{|project| project.repository.try(:open_issues_count) || 0}.reverse.each {|project| puts "#{project.platform}/#{project.name} (#{project.repository.try(:open_issues_count)})" };nil

    # cii projects that andrew's commited to
    andrew = RepositoryUser.host('GitHub').find_by_login('andrew')
    Contribution.where(repository_id: cii_repository_ids, repository_user_id: andrew.id).sum(:count) # 265 commits
    repo_ids = Contribution.where(repository_id: cii_repository_ids, repository_user_id: andrew.id).group(:repository_id).count.keys
    Repository.where(id: repo_ids).each{|r| puts r.url};nil

    # breakdown of percentage commits to cii deps by civit tech peeps

    dep_contribs = cii_projects.map do |dep|
      total_commits = Contribution.where(repository_id: dep.repository_id).sum(:count)
      civic_commits = Contribution.where(repository_id: dep.repository_id, repository_user_id: civic_tech_contributor_ids).sum(:count)
      {
        dependency: "#{dep.platform}/#{dep.name}",
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
      end
      if invalid.any?
        puts "#{repo.url} - #{repo.license}"
        invalid.each do |dep|
          next if dep.project.normalize_licenses.blank?
          puts "  #{dep.platform}/#{dep.project.name} - #{dep.project.normalize_licenses.join('/')}"
        end
      end
    end;nil

  end
end
