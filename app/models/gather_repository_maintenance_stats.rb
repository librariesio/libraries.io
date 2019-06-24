class GatherRepositoryMaintenanceStats
    def self.gather_bitbucket_stats(repository)
        # only support Github and Bitbucket repos for now
        # check to make sure the Project URLs are also pointing to a Github or Bitbucket repository
        unless stats_enabled?(repository)
            # if this repository should not have stats, delete any existing ones and return immediately
            repository.repository_maintenance_stats.destroy_all
            return
        end

        now = DateTime.current
        metrics = []

        # get latest issues and pull requests and store them in the database
        repository.download_issues
        repository.download_pull_requests

        metrics << MaintenanceStats::Stats::Bitbucket::CommitsStat.new(repository.retrieve_commits).get_stats

        metrics << MaintenanceStats::Stats::Bitbucket::IssueRates.new(repository.issues).get_stats

        # add_metrics_to_repo(repository, metrics)
        metrics
    end

    def self.gather_stats(repository)
        # only support Github repos for now
        # check to make sure the Project URLs are also pointing to a Github repository
        unless stats_enabled?(repository)
            # if this repository should not have stats, delete any existing ones and return immediately
            repository.repository_maintenance_stats.destroy_all
            return
        end

        return gather_github_stats(repository) if github?(repository)
        return gather_bitbucket_stats(repository) if bitbucket?(repository)
    end

    def self.gather_github_stats(repository)
        client = AuthToken.v4_client
        v3_client = AuthToken.client({auto_paginate: false})
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
          result = MaintenanceStats::Queries::RepositoryContributorStatsQuery.new(v3_client).query(params: {full_name: repository.full_name})
          metrics << MaintenanceStats::Stats::V3ContributorCountStats.new(result).get_stats
        rescue Octokit::Error => e
          Rails.logger.warn(e.message)
        end

        begin
          result = MaintenanceStats::Queries::IssuesQuery.new(v3_client).query(params: {full_name: repository.full_name, since: (now - 1.year).iso8601})
          metrics << MaintenanceStats::Stats::V3IssueStats.new(result).get_stats
        rescue Octokit::Error => e

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

    def self.stats_enabled?(repository)
        github?(repository) || bitbucket?(repository)
    end

    def self.github?(repository)
        repository.host_type == "GitHub" && repository.projects.all? {|project| project.github_name_with_owner.present?} 
    end

    def self.bitbucket?(repository)
        repository.host_type == "Bitbucket" && repository.projects.all? {|project| project.bitbucket_name_with_owner.present?} 
    end
end
