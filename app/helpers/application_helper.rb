require 'uri'

module ApplicationHelper
  include SanitizeUrl

  def package_link(project, platform, version = nil)
    name = project.name
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
      "https://www.npmjs.com/package/#{name}"
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
    when 'Biicode'
      "https://www.biicode.com/#{name}/#{version}"
    when 'CPAN'
      "https://metacpan.org/release/#{name}"
    when 'CRAN'
      "http://cran.r-project.org/web/packages/#{name}/index.html"
    when 'CocoaPods'
      "http://cocoapods.org/pods/#{name}"
    when 'Julia'
      "http://pkg.julialang.org/?pkg=#{name}&ver=release"
    when 'Atom'
      "https://atom.io/packages/#{name}"
    when 'Elm'
      "http://package.elm-lang.org/packages/#{name}/#{version || 'latest'}"
    when 'Clojars'
      "https://clojars.org/#{name}" + (version ? "/versions/#{version}" : "")
    when 'Maven'
      if version
        "http://search.maven.org/#artifactdetails%7C#{name.gsub(':', '%7C')}%7C#{version}%7Cjar"
      else
        group, artifact = name.split(':')
        "http://search.maven.org/#search%7Cgav%7C1%7Cg%3A%22#{group}%22%20AND%20a%3A%22#{artifact}%22"
      end
    when 'Meteor'
      "https://atmospherejs.com/#{name.gsub(':', '/')}"
    when 'PlatformIO'
      "http://platformio.org/#!/lib/show/#{project.pm_id}/#{name}"
    end
  end

  def documentation_url(name, platform, version = nil)
    case platform
    when 'Rubygems'
      "http://www.rubydoc.info/gems/#{name}/#{version}"
    when 'Go'
      "http://godoc.org/#{name}"
    when 'Pub'
      "http://www.dartdocs.org/documentation/#{name}/#{version}"
    when 'CRAN'
      "http://cran.r-project.org/web/packages/#{name}/#{name}.pdf"
    when 'Hex'
      "http://hexdocs.pm/#{name}/#{version}"
    when 'CocoaPods'
      "http://cocoadocs.org/docsets/#{name}/#{version}"
    end
  end

  def install_instructions(project, platform, version = nil)
    name = project.name
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
    when 'Atom'
      "apm install #{name}" + (version ? "@#{version}" : "")
    when 'Nimble'
      "nimble install #{name}" + (version ? "@##{version}" : "")
    when 'Go'
      "go get #{name}"
    when 'NuGet'
      "Install-Package #{name}" + (version ? " -Version #{version}" : "")
    when 'Meteor'
      "meteor add #{name}" + (version ? "@=#{version}" : "")
    when 'Elm'
      "elm-package install #{name} #{version}"
    when 'PlatformIO'
      "platformio lib install #{project.pm_id}"
    end
  end

  def title(page_title)
    content_for(:title) { page_title }
  end

  def description(page_description)
    content_for(:description) { page_description }
  end

  def linked_licenses(licenses)
    return 'Missing' if licenses.empty?
    licenses.map{|l| link_to format_license(l), license_path(l) }.join('/').html_safe
  end

  def linked_keywords(keywords)
    keywords.map{|k| link_to k, search_path(keywords: k.downcase) }.join(', ').html_safe
  end

  def platform_name(platform)
    if platform.downcase == 'npm'
      return 'npm'
    elsif platform.downcase == 'biicode'
      return 'biicode'
    else
      return platform
    end
  end

  def favicon(size)
    libicon = "https://libicons.herokuapp.com/favicon.ico"
    @color ? "#{libicon}?hex=#{URI::escape(@color)}&size=#{size}" : "/favicon-#{size}.png"
  end

  def format_license(license)
    return 'Missing' if license.blank?
    Project.format_license(license)
  end

  def stats_for(title, records)
    render 'table', title: title, records: records
  end
end
