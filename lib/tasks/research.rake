namespace :research do
  desc 'civic tech dependency research'
  task civic_tech: :environment do
    repos = [
      'DemocracyClub/WhoCanIVoteFor',
      'MuckRock/muckrock',
      'okfde/fragdenstaat_de',
      'codeforamerica/recordtrac'
    ]

    github_repositories = GithubRepository.where(full_name: repos)

    projects = github_repositories.map(&:dependency_projects).flatten.map {|project| "#{project.platform}/#{project.name}" }

    project_counts = projects.reduce (Hash.new(0)) {|counts, el| counts[el]+=1; counts}

    project_counts.select{|k,v| v > 1 }.sort_by{|k,v| -v}.each {|k,v| puts "#{k} (#{v})" };nil
  end
end
