module Repositories
  class Base
    COLOR = '#fff'
    LIBRARIAN_SUPPORT = false
    LIBRARIAN_PLANNED = false
    SECURITY_PLANNED = false
    HIDDEN = false

    def self.platforms
      @platforms ||= Repositories.constants
        .reject { |platform| platform == :Base }
        .map{|sym| "Repositories::#{sym}".constantize }
        .reject { |platform| platform::HIDDEN }
        .sort_by(&:name)
    end

    def self.format_name(platform)
      return nil if platform.nil?
      platforms.find{|p| p.to_s.demodulize.downcase == platform.downcase }.to_s.demodulize
    end

    def self.color
      self::COLOR
    end

    def self.formatted_name
      self.to_s.demodulize
    end

    def self.package_link(project, version = nil)
      name = project.name
      platform = project.platform
      case platform
      when 'Inqlude'
        "https://inqlude.org/libraries/#{name}.html"
      when 'Hex'
        "https://hex.pm/packages/#{name}/#{version}"
      when 'Dub'
        "http://code.dlang.org/packages/#{name}" + (version ? "/#{version}" : "")
      when 'Emacs'
        "http://melpa.org/#/#{name}"
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
      when 'CPAN'
        "https://metacpan.org/release/#{name}"
      when 'CRAN'
        "https://CRAN.R-project.org/package=#{name}"
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
        "https://atmospherejs.com/#{name.tr(':', '/')}"
      when 'PlatformIO'
        "http://platformio.org/lib/show/#{project.pm_id}/#{name}"
      when 'Homebrew'
        "http://brewformulas.org/#{name}"
      when 'Shards'
        "https://crystal-shards-registry.herokuapp.com/shards/#{name}"
      when 'Haxelib'
        "https://lib.haxe.org/p/#{name}/#{version}"
      end
    end

    def self.download_url(name, platform, version = nil)
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

    def self.documentation_url(name, platform, version = nil)
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

    def self.install_instructions(project, platform, version = nil)
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

    def self.platform_name(platform)
      if platform.downcase == 'npm'
        return 'npm'
      elsif platform.downcase == 'wordpress'
        return 'WordPress'
      else
        return platform
      end
    end

    def self.dependency_platform(platform_string)
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

    def self.save(project, include_versions = true)
      mapped_project = mapping(project).delete_if { |_key, value| value.blank? }
      return false unless mapped_project
      puts "Saving #{mapped_project[:name]}"
      dbproject = Project.find_or_initialize_by({:name => mapped_project[:name], :platform => self.name.demodulize})
      if dbproject.new_record?
        dbproject.assign_attributes(mapped_project.except(:name, :releases))
        dbproject.save
      else
        dbproject.update_attributes(mapped_project.except(:name, :releases))
      end

      if include_versions && self::HAS_VERSIONS
        versions(project).each do |version|
          dbproject.versions.find_or_create_by(version)
        end
      end

      if self::HAS_DEPENDENCIES
        save_dependencies(mapped_project)
      end
      dbproject.reload
      dbproject.last_synced_at = Time.now
      dbproject.save
      dbproject
    end

    def self.update(name, include_versions = true)
      begin
        save(project(name), include_versions)
      rescue SystemExit, Interrupt
        exit 0
      rescue Exception
        raise unless ENV["RACK_ENV"] == "production"
      end
    end

    def self.import_async
      project_names.each { |name| RepositoryDownloadWorker.perform_async(self.name.demodulize, name) }
    end

    def self.import_recent_async
      recent_names.each { |name| RepositoryDownloadWorker.perform_async(self.name.demodulize, name) }
    end

    def self.import_new_async
      new_names.each { |name| RepositoryDownloadWorker.perform_async(self.name.demodulize, name) }
    end

    def self.import(include_versions = true)
      project_names.each { |name| update(name, include_versions) }
    end

    def self.import_recent
      recent_names.each { |name| update(name) }
    end

    def self.new_names
      names = project_names
      existing_names = []
      Project.platform(self.name.demodulize).select(:id, :name).find_each {|project| existing_names << project.name }
      names - existing_names
    end

    def self.import_new
      new_names.each { |name| update(name) }
    end

    def self.save_dependencies(mapped_project)
      name = mapped_project[:name]
      proj = Project.find_by(name: name, platform: self.name.demodulize)
      proj.versions.each do |version|
        deps = dependencies(name, version.number, mapped_project)
        next unless deps && deps.any? && version.dependencies.empty?
        deps.each do |dep|
          unless version.dependencies.find_by_project_name dep[:project_name]
            named_project = Project.platform(self.name.demodulize).where('lower(name) = ?', dep[:project_name].downcase).first.try(:id)
            version.dependencies.create(dep.merge(project_id: named_project.try(:strip)))
          end
        end
      end
    end

    def self.dependencies(_name, _version, _project)
      []
    end

    def self.get(url, options = {})
      Oj.load(get_raw(url, options))
    end

    def self.get_raw(url, options = {})
      request(url, options).body
    end

    def self.request(url, options = {})
      connection = Faraday.new url, options do |builder|
        builder.use :http_cache, store: Rails.cache, logger: Rails.logger, shared_cache: false, serializer: Marshal
        builder.use FaradayMiddleware::Gzip
        builder.use FaradayMiddleware::FollowRedirects, limit: 3
        builder.adapter :typhoeus
      end
      connection.get
    end

    def self.get_html(url, options = {})
      Nokogiri::HTML(get_raw(url, options))
    end

    def self.get_json(url)
      get(url, headers: { 'Accept' => "application/json"})
    end

    def self.repo_fallback(repo, homepage)
      repo = '' if repo.nil?
      homepage = '' if homepage.nil?
      repo_gh = GithubUrls.parse(repo)
      homepage_gh = GithubUrls.parse(homepage)
      if repo_gh.present?
        return "https://github.com/#{repo_gh}"
      elsif homepage_gh.present?
        return "https://github.com/#{homepage_gh}"
      else
        repo
      end
    end
  end
end
