class GatherRepositoryMaintenanceStats
    attr_accessor :client

    def self.gather_stats(repository)
        client = AuthToken.v4_client
        v3_client = AuthToken.client
        now = DateTime.now

        metric_results = []

        result = client.query(Queries::FullRepoQuery, variables: {owner: repository.owner_name, repo_name: repository.project_name})

        # sometimes the repo just doesn't exist
        # there a few that I've seen that redirect when you try and go to the github URL in libraries
        if result.data.nil? || result.data.repository.nil?
            Rails.logger.warn("#{repository.owner_name}/#{repository.project_name} is not a valid repository and should be fixed")
        end

        release_stats = ReleaseStats.new(result)

        page_info = { has_next_page: true, cursor: nil}
        while(page_info[:has_next_page])
            releases = client.query(Queries::ReleasesQuery, variables: {owner: repository.owner_name, repo_name: repository.project_name, cursor: page_info[:cursor]})
            page_info = release_stats.add_releases(releases, now - 365)
        end
        release_stats = release_stats.get_stats(now)

        metric_results << release_stats

        metric_results << IssueRates.new(result).get_stats

        metric_results << PullRequestRates.new(result).get_stats
        metric_results << AverageCommitDate.new(result).get_stats

        commit_stats = CommitCounts.new

        commit_stats.last_week_commits = CommitCounts.pull_out_count(client.query(Queries::CommitCountsQuery, variables: {owner: repository.owner_name, repo_name: repository.project_name, start_date: (now - 7).iso8601}))
        commit_stats.last_month_commits = CommitCounts.pull_out_count(client.query(Queries::CommitCountsQuery, variables: {owner: repository.owner_name, repo_name: repository.project_name, start_date: (now - 30).iso8601}))
        commit_stats.last_two_month_commits = CommitCounts.pull_out_count(client.query(Queries::CommitCountsQuery, variables: {owner: repository.owner_name, repo_name: repository.project_name, start_date: (now - 60).iso8601}))
        commit_stats.last_year_commits = CommitCounts.pull_out_count(client.query(Queries::CommitCountsQuery, variables: {owner: repository.owner_name, repo_name: repository.project_name, start_date: (now - 365).iso8601}))

        metric_results << commit_stats.get_stats

        contributor_result = Queries::RepositoryContributorsQuery.repository_contributors(v3_client, result.data.repository.name_with_owner)
        metric_results << Contributors.new(contributor_result).get_stats

        add_metrics_to_repo(repository, metric_results)
    end

    private

    def self.add_metrics_to_repo(repository, results)
        # create one hash with all results
        results.reduce(Hash.new, :merge).each do |category, value|
            repository.repository_maintenance_stats.find_or_create_by(value: value.to_s, category: category.to_s)
        end
    end
end