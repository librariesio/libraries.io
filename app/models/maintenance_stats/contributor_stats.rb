class Contributors
    attr_accessor :total_contributors
    def initialize(dataset)
        @total_contributors = 0
        @total_contributors = dataset.count unless dataset.nil?
    end

    def get_stats
        {
            "total_contributors": total_contributors,
        }
    end
end