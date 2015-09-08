require_relative("#{Rails.root}/lib/repositories/base.rb")
Dir["#{Rails.root}/lib/repositories/*.rb"].each {|file| require file }
