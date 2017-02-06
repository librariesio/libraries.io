module PackageManager
  class Base
    COLOR = '#fff'
    LIBRARIAN_SUPPORT = false
    LIBRARIAN_PLANNED = false
    SECURITY_PLANNED = false
    HIDDEN = false

    def self.platforms
      @platforms ||= begin
        Dir[Rails.root.join('app', 'models', 'package_manager', '*.rb')].each do|file|
          require file unless file.match(/base.rb$/)
        end
        PackageManager.constants
          .reject { |platform| platform == :Base }
          .map{|sym| "PackageManager::#{sym}".constantize }
          .reject { |platform| platform::HIDDEN }
          .sort_by(&:name)
      end
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

    def self.package_link(_project, _version = nil)
      nil
    end

    def self.download_url(_name, _version = nil)
      nil
    end

    def self.documentation_url(_name, _version = nil)
      nil
    end

    def self.install_instructions(_project, _version = nil)
      nil
    end

    def self.check_status_url(project)
      package_link(project)
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

    def self.save(project)
      return unless project.present?
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

      if self::HAS_VERSIONS
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

    def self.update(name)
      begin
        project = project(name)
        save(project) if project.present?
      rescue SystemExit, Interrupt
        exit 0
      rescue Exception => exception
        if ENV["RACK_ENV"] == "production"
          Bugsnag.notify(exception)
        else
          raise
        end
      end
    end

    def self.import_async
      download_async(project_names)
    end

    def self.import_recent_async
      download_async(recent_names)
    end

    def self.import_new_async
      download_async(new_names)
    end

    def self.import
      project_names.each { |name| update(name) }
    end

    def self.import_recent
      recent_names.each { |name| update(name) }
    end

    def self.import_new
      new_names.each { |name| update(name) }
    end

    def self.new_names
      names = project_names
      existing_names = []
      Project.platform(self.name.demodulize).select(:id, :name).find_each {|project| existing_names << project.name }
      names - existing_names
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

    def self.map_dependencies(deps, kind, optional = false)
      deps.map do |k,v|
        {
          project_name: k,
          requirements: v,
          kind: kind,
          optional: optional,
          platform: self.name.demodulize
        }
      end
    end

    def self.find_and_map_dependencies(name, version, _project)
      dependencies =find_dependencies(name, version)
      return [] unless dependencies.any?
      dependencies.map do |dependency|
        {
          project_name: dependency["name"],
          requirements: dependency["version"],
          kind: dependency["type"],
          platform: self.name.demodulize
        }
      end
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

    private

    def self.get(url, options = {})
      Oj.load(get_raw(url, options))
    end

    def self.get_raw(url, options = {})
      request(url, options).body
    end

    def self.request(url, options = {})
      connection = Faraday.new url.strip, options do |builder|
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

    def self.download_async(names)
      names.each { |name| PackageManagerDownloadWorker.perform_async(self.name.demodulize, name) }
    end
  end
end
