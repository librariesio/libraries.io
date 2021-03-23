# frozen_string_literal: true

class Coordinate
  def self.generate(project)
    "#{project.platform}/#{project.name}".downcase
  end
end
