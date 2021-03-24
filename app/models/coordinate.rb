# frozen_string_literal: true

class Coordinate
  def self.generate(project, version_number = nil)
    [
      project.platform.downcase,
      ERB::Util.url_encode(project.name.downcase),
      version_number ? ERB::Util.url_encode(version_number) : nil,
    ].compact.join("/")
  end
end
