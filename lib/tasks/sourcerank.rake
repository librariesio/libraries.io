namespace :sourcerank do
  task seed: :environment do
    Rails.logger.level = Logger::DEBUG
    # start with projects that have zero runtime dependencies

    platform = 'Rubygems'
    eager_loads = [{versions: {runtime_dependencies: :project}}, :registry_users, {repository: :readme}]

    maximums = SourceRankCalculator.maximums(platform)

    scope = Project.platform(platform).includes(eager_loads)

    scope.where(runtime_dependencies_count: 0).find_each do |project|
      score = SourceRankCalculator.new(project, maximums).overall_score.round
      next if project.sourcerank_2 == score
      project.update_columns(sourcerank_2: score,
                             sourcerank_2_last_calculated: Time.zone.now)
      puts "[#{project.runtime_dependencies_count}] #{project.name}: #{score}"
    end

    # projects that have between 1 and 6 runtime dependencies in order
    counts = (1..6).to_a
    counts.each do |count|
      puts "#{'*'*10} #{count} #{'*'*10}"

      scope.where(runtime_dependencies_count: counts).find_each do |project|
        score = SourceRankCalculator.new(project, maximums).overall_score.round
        next if project.sourcerank_2 == score
        project.update_columns(sourcerank_2: score,
                               sourcerank_2_last_calculated: Time.zone.now)
        puts "[#{project.runtime_dependencies_count}] #{project.name}: #{score}"
      end
    end

    puts "#{'*'*10} >#{counts.last} #{'*'*10}"

    # projects with even more dependencies
    scope.where('runtime_dependencies_count > ?', counts.last).find_each do |project|
      score = SourceRankCalculator.new(project, maximums).overall_score.round
      next if project.sourcerank_2 == score
      project.update_columns(sourcerank_2: score,
                             sourcerank_2_last_calculated: Time.zone.now)
      puts "[#{project.runtime_dependencies_count}] #{project.name}: #{score}"
    end
  end
end
