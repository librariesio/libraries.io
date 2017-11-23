module PackageManager
  class Jam < Base
    HAS_VERSIONS = true
    HAS_DEPENDENCIES = false
    SECURITY_PLANNED = true
    HIDDEN = true
    URL = 'http://jamjs.org/'
    COLOR = '#f1e05a'

    def project(_name)
      nil
    end
  end
end
