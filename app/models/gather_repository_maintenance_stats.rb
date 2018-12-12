class GatherRepositoryMaintenanceStats
    def self.gather_stats(repository: nil)
        repository = Repository.first if repository.nil?
        client = AuthToken.v4_client
        v3_client = AuthToken.client
        stats_to_run = get_stats_to_run(repository)

        clients = {
            v3: v3_client,
            v4: client
        }

        metrics = []

        stats_to_run.each do |stat_run|
            query_to_run = stat_run[:query].new(clients[stat_run[:query].client_type])
            result = query_to_run.query(params: stat_run[:variables])
            stat_run[:stat_class].each do |stat_class|
                metrics << stat_class.new(result).get_stats
            end
        end

        add_metrics_to_repo(repository, metrics)

        metrics
    end

    private

    def self.add_metrics_to_repo(repository, results)
        # create one hash with all results
        results.reduce(Hash.new, :merge).each do |category, value|
            repository.repository_maintenance_stats.find_or_create_by(value: value.to_s, category: category.to_s)
        end
    end

    def self.get_stats_to_run(repository)
        now = DateTime.now
        [{
            query: MaintenanceStats::FullRepoQuery,
            variables: {owner: repository.owner_name, repo_name: repository.project_name},
            stat_class: [MaintenanceStats::IssueRates, MaintenanceStats::PullRequestRates, MaintenanceStats::AverageCommitDate]
        },
        {
            query: MaintenanceStats::RepositoryContributorsQuery,
            variables: {full_name: repository.full_name},
            stat_class: [MaintenanceStats::Contributors]
        },
        {
            query: MaintenanceStats::RepoReleasesQuery,
            variables: {owner: repository.owner_name, repo_name: repository.project_name, end_date: now - 365},
            stat_class: [MaintenanceStats::ReleaseStats]
        },
        {
            query: MaintenanceStats::CommitCountQuery,
            variables: {owner: repository.owner_name, repo_name: repository.project_name, start_date: (now - 7).iso8601},
            stat_class: [MaintenanceStats::LastWeekCommitsStat]
        },
        {
            query: MaintenanceStats::CommitCountQuery,
            variables: {owner: repository.owner_name, repo_name: repository.project_name, start_date: (now - 30).iso8601},
            stat_class: [MaintenanceStats::LastMonthCommitsStat]
        },
        {
            query: MaintenanceStats::CommitCountQuery,
            variables: {owner: repository.owner_name, repo_name: repository.project_name, start_date: (now - 60).iso8601},
            stat_class: [MaintenanceStats::LastTwoMonthCommitsStat]
        },
        {
            query: MaintenanceStats::CommitCountQuery,
            variables: {owner: repository.owner_name, repo_name: repository.project_name, start_date: (now - 365).iso8601},
            stat_class: [MaintenanceStats::LastYearCommitsStat]
        }]
    end
end