class Repositories
  class Hackage
    def self.project_names
      HTTParty.get('http://hackage.haskell.org/packages/', headers: {"Accept" => 'application/json'}).flat_map(&:values)
    end

    def self.project(name)

    end

    def self.keys
      []
    end

    def self.mapping(project)
      #
    end
  end
end
