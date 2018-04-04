namespace :sourcerank do
  task seed: :environment do
    Rails.logger.level = Logger::DEBUG
    # start with projects that have zero runtime dependencies

    platform = 'Rubygems'
    eager_loads = [{versions: {runtime_dependencies: :project}}, :registry_users, {repository: :readme}]

    maximums = SourceRankCalculator.maximums(platform)

    Project.platform(platform).where(runtime_dependencies_count: 0).includes(eager_loads).find_each do |project|
      calculator = SourceRankCalculator.new(project, maximums)
      puts "#{project.name}: #{calculator.overall_score}"
    end

    # projects that have 1 runtime dependency

    Project.platform(platform).where(runtime_dependencies_count: 1).includes(eager_loads).find_each do |project|
      calculator = SourceRankCalculator.new(project, maximums)
      puts "#{project.name}: #{calculator.overall_score}"
    end
  end
end
