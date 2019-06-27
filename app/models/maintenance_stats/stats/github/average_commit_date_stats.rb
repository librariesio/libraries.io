module MaintenanceStats
  module Stats
    module Github
      class AverageCommitDate < BaseStat
        def get_stats
            {
                "average_commit_date": average_commit_date,
            }
        end

        private 
                
        def average_commit_date
            return if @results.data.repository.default_branch_ref.nil?
            edges = @results.data.repository.default_branch_ref.target.history.edges
    
            dates = edges.map { |edge| Time.parse(edge.node.authored_date) }
            return if dates.count == 0
            Time.at(dates.map(&:to_i).sum / dates.count).utc
        end
      end
    end
  end
end