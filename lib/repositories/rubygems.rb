require 'gems'

class Repositories
  class Rubygems
    def self.project_names
      gems = Marshal.load(Gem.gunzip(HTTParty.get("http://production.cf.rubygems.org/specs.4.8.gz").parsed_response))
      gems.map(&:first).uniq
    end

    def self.project(name)
      Gems.info name
    end
  end
end
