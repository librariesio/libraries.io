module MaintenanceStats
  module Stats
    module Github
      class IssueRates < BaseStat
        def get_stats
          {
            issue_closure_rate: issue_closure_rate,
            closed_issue_count: closed_issues_count,
            open_issue_count: open_issues_count,
          }
        end

        private
        
        def total_issues_count
          return 0 if closed_issues_count.nil? && open_issues_count.nil?
          closed_issues_count + open_issues_count
        end
        
        def issue_closure_rate
          return 1.0 if total_issues_count == 0
          closed_issues_count.to_f / total_issues_count.to_f
        end
        
        def open_issues_count
          @results.data.repository&.open_issues.total_count
        end
        
        def closed_issues_count
          @results.data.repository&.closed_issues.total_count
        end
      end
    end
  end
end