ActiveSupport::Logger.class_eval do
  def self.broadcast(logger)
    Module.new do
    end
  end
end
