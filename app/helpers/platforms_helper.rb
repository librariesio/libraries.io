module PlatformsHelper
  def package_link(project, version = nil)
    Repositories::Base.package_link(project, version)
  end

  def download_url(name, platform, version = nil)
    case platform
    when 'Rubygems'
      "https://rubygems.org/downloads/#{name}-#{version}.gem"
    when 'Atom'
      "https://www.atom.io/api/packages/#{name}/versions/#{version}/tarball"
    when 'Cargo'
      "https://crates.io/api/v1/crates/#{name}/#{version}/download"
    when 'CRAN'
      "https://cran.r-project.org/src/contrib/#{name}_#{version}.tar.gz"
    when 'Emacs'
      "http://melpa.org/packages/#{name}-#{version}.tar"
    when 'Hackage'
      "http://hackage.haskell.org/package/#{name}-#{version}/#{name}-#{version}.tar.gz"
    when 'Haxelib'
      "https://lib.haxe.org/p/#{name}/#{version}/download/"
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
    when 'Cargo'
      "https://docs.rs/#{name}/#{version}"
    end
  end

  def install_instructions(project, platform, version = nil)
    name = project.name
    case platform
    when 'Rubygems'
      "gem install #{name}" + (version ? " -v #{version}" : "")
    when 'NPM'
      "npm install #{name}" + (version ? "@#{version}" : "")
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
    when 'Inqlude'
      "inqlude install #{name}"
    when 'Homebrew'
      "brew install #{name}"
    when 'Haxelib'
      "haxelib install #{name} " + (version ? " #{version}" : "")
    end
  end

  def platform_name(platform)
    if platform.downcase == 'npm'
      return 'npm'
    elsif platform.downcase == 'wordpress'
      return 'WordPress'
    else
      return platform
    end
  end

  def dependency_platform(platform_string)
    return platform_string if platform_string.nil?
    case platform_string.downcase
    when 'rubygemslockfile'
      'rubygems'
    when 'cocoapodslockfile'
      'cocoapods'
    when 'nugetlockfile', 'nuspec'
      'nuget'
    when 'packagistlockfile'
      'packagist'
    when 'gemspec'
      'rubygems'
    when 'npmshrinkwrap'
      'npm'
    else
      platform_string.downcase
    end
  end
end
