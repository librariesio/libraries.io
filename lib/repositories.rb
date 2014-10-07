Dir["lib/repositories/*.rb"].each {|file| require "./#{file}" }
class Repositories
  def self.descendants
    constants.collect {|const_name| const_get(const_name)}
  end
end
