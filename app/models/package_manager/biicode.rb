# frozen_string_literal: true
module PackageManager
  class Biicode < Base
    HAS_VERSIONS = true
    HAS_DEPENDENCIES = true
    HIDDEN = true
    URL = 'https://github.com/biicode/'
    COLOR = '#f34b7d'

    def self.formatted_name
      'biicode'
    end
  end
end
