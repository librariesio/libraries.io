module ApplicationHelper
  def package_link(name, platform)
    case platform
    when 'Hex'
      "https://hex.pm/packages/#{name}"
    when 'Dub'
      "http://code.dlang.org/packages/#{name}"
    when 'Emacs'
      "http://melpa.org/#/#{name}"
    when 'Jam'
      "http://jamjs.org/packages/#/details/#{name}"
    when 'Pub'
      "https://pub.dartlang.org/packages/#{name}"
    when 'NPM'
      "https://www.npmjs.com/package/#{name}"
    when 'Rubygems'
      "https://rubygems.org/gems/#{name}"
    when 'Sublime'
      "https://packagecontrol.io/packages/#{name}"
    when 'Pypi'
      "https://pypi.python.org/pypi/#{name}"
    when 'Packagist'
      "https://packagist.org/packages/#{name}"
    end
  end
end
