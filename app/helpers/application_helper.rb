module ApplicationHelper
  def package_link(name, platform, version = nil)
    case platform
    when 'Hex'
      "https://hex.pm/packages/#{name}/#{version}"
    when 'Dub'
      "http://code.dlang.org/packages/#{name}" + (version ? "/#{version}" : "")
    when 'Emacs'
      "http://melpa.org/#/#{name}"
    when 'Jam'
      "http://jamjs.org/packages/#/details/#{name}/#{version}"
    when 'Pub'
      "https://pub.dartlang.org/packages/#{name}"
    when 'NPM'
      "https://www.npmjs.com/package/#{name}/#{version}"
    when 'Rubygems'
      "https://rubygems.org/gems/#{name}" + (version ? "/versions/#{version}" : "")
    when 'Sublime'
      "https://packagecontrol.io/packages/#{name}"
    when 'Pypi'
      "https://pypi.python.org/pypi/#{name}/#{version}"
    when 'Packagist'
      "https://packagist.org/packages/#{name}##{version}"
    when 'Cargo'
      "https://crates.io/crates/#{name}/#{version}"
    when 'Hackage'
      "http://hackage.haskell.org/package/#{name}" + (version ? "-#{version}" : "")
    end
  end

  def title(page_title)
    content_for(:title) { page_title }
  end

  def linked_licenses(licenses)
    licenses.split(',').map{|l| link_to l, license_path(l) }.join(', ').html_safe
  end

  def linked_keywords(keywords)
    keywords.split(',').map{|k| link_to k, search_path(q: k) }.join(', ').html_safe
  end
end
