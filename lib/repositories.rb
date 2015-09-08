require("#{Rails.root}/lib/repositories/base.rb")
Dir["#{Rails.root}/lib/repositories/*.rb"].each {|file| require file }
class Repositories
  def self.descendants
    constants.collect {|const_name| const_get(const_name)}
  end
end
require("#{Rails.root}/lib/download.rb")
