module ApplicationHelper
  include SanitizeUrl

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
    when 'Go'
      "http://go-search.org/view?id=#{name}"
    when 'Wordpress'
      "https://wordpress.org/plugins/#{name}/#{version}"
    when 'NuGet'
      "https://www.nuget.org/packages/#{name}/#{version}"
    when 'CPAN'
      "https://metacpan.org/release/#{name}"
    when 'Maven'
      if version
        "http://search.maven.org/#artifactdetails%7C#{name.gsub(':', '%7C')}%7C#{version}%7Cjar"
      else
        group, artifact = name.split(':')
        "http://search.maven.org/#search%7Cgav%7C1%7Cg%3A%22#{group}%22%20AND%20a%3A%22#{artifact}%22"
      end
    end
  end

  def install_instructions(name, platform, version = nil)
    case platform
    when 'Rubygems'
      "gem install #{name}" + (version ? " -v #{version}" : "")
    when 'NPM'
      "npm install #{name}" + (version ? "@#{version}" : "")
    when 'Jam'
      "jam install #{name}" + (version ? "@#{version}" : "")
    when 'Bower'
      "bower install #{name}" + (version ? "##{version}" : "")
    when 'Dub'
      "dub fetch #{name}" + (version ? " --version #{version}" : "")
    when 'Hackage'
      "cabal install #{name}" + (version ? "-#{version}" : "")
    when 'PyPi'
      "pip install #{name}" + (version ? "==#{version}" : "")
    when 'Go'
      "go get #{name}"
    when 'NuGet'
      "Install-Package #{name}" + (version ? " -Version #{version}" : "")
    end
  end

  def title(page_title)
    content_for(:title) { page_title }
  end

  def description(page_description)
    content_for(:description) { page_description }
  end

  def linked_licenses(licenses)
    licenses.map{|l| link_to l, license_path(l) }.join('/').html_safe
  end

  def linked_keywords(keywords)
    keywords.split(',').map{|k| link_to k, search_path(keywords: k) }.join(', ').html_safe
  end
end
