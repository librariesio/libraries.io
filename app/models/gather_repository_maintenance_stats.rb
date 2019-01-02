class GatherRepositoryMaintenanceStats
    def self.gather_stats(repository)
        return unless repository.host_type == "GitHub" # only support Github repos for now
        client = AuthToken.v4_client
        v3_client = AuthToken.client
        now = DateTime.current

        metrics = []

        result = MaintenanceStats::Queries::FullRepoQuery.new(client).query( params: {owner: repository.owner_name, repo_name: repository.project_name} )
        unless check_for_v4_error_response(result)
            metrics << MaintenanceStats::Stats::IssueRates.new(result).get_stats
            metrics << MaintenanceStats::Stats::PullRequestRates.new(result).get_stats
            metrics << MaintenanceStats::Stats::AverageCommitDate.new(result).get_stats
        end

        result = MaintenanceStats::Queries::RepoReleasesQuery.new(client).query( params: {owner: repository.owner_name, repo_name: repository.project_name, end_date: now - 1.year} )
        unless check_for_v4_error_response(result)
            metrics << MaintenanceStats::Stats::ReleaseStats.new(result).get_stats
        end

        result = MaintenanceStats::Queries::CommitCountQuery.new(client).query(params: {owner: repository.owner_name, repo_name: repository.project_name, start_date: (now - 1.week).iso8601} )
        metrics << MaintenanceStats::Stats::LastWeekCommitsStat.new(result).get_stats unless check_for_v4_error_response(result)

        result = MaintenanceStats::Queries::CommitCountQuery.new(client).query(params: {owner: repository.owner_name, repo_name: repository.project_name, start_date: (now - 1.month).iso8601} )
        metrics << MaintenanceStats::Stats::LastMonthCommitsStat.new(result).get_stats unless check_for_v4_error_response(result)

        result = MaintenanceStats::Queries::CommitCountQuery.new(client).query(params: {owner: repository.owner_name, repo_name: repository.project_name, start_date: (now - 2.months).iso8601} )
        metrics << MaintenanceStats::Stats::LastTwoMonthCommitsStat.new(result).get_stats unless check_for_v4_error_response(result)

        result = MaintenanceStats::Queries::CommitCountQuery.new(client).query(params: {owner: repository.owner_name, repo_name: repository.project_name, start_date: (now - 1.year).iso8601} )
        metrics << MaintenanceStats::Stats::LastYearCommitsStat.new(result).get_stats unless check_for_v4_error_response(result)
                
        begin
            result = MaintenanceStats::Queries::CommitCountQueryV3.new(v3_client).query(params: {full_name: repository.full_name} )
            metrics << MaintenanceStats::Stats::V3CommitsStat.new(result).get_stats
        rescue Octokit::Error => e
            Rails.logger.warn(e.message)
        end

        begin
            result = MaintenanceStats::Queries::RepositoryContributorsQuery.new(v3_client).query(params: {full_name: repository.full_name} )
            metrics << MaintenanceStats::Stats::Contributors.new(result).get_stats
        rescue Octokit::Error => e
            Rails.logger.warn(e.message)
        end

        add_metrics_to_repo(repository, metrics)

        metrics
    end

    private

    def self.check_for_v4_error_response(response)
        # errors can be stored in the response from Github or can be stored in the response object from HTTP errors
        response.errors.each do |message|
            Rails.logger.warn(message)
        end
        response.data.errors.each do |message|
            Rails.logger.warn(message)
        end unless response.data.errors.nil?
        # if we have either type of error or there is no data return true
        return response.data.nil? || response.errors.any? || response.data.errors.any?
        false
    end

    def self.add_metrics_to_repo(repository, results)
        # create one hash with all results
        results.reduce(Hash.new, :merge).each do |category, value|
            unless value.nil?
                stat = repository.repository_maintenance_stats.find_or_create_by(category: category.to_s)
                stat.update!(value: value.to_s)
                stat.touch unless stat.changed?  # we always want to update updated_at for later querying
            end
        end
    end
end