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
end
