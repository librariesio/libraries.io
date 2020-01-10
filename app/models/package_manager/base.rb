module PackageManager
  class Base
    COLOR = '#fff'
    BIBLIOTHECARY_SUPPORT = false
    BIBLIOTHECARY_PLANNED = false
    SECURITY_PLANNED = false
    HIDDEN = false
    HAS_OWNERS = false
    ENTIRE_PACKAGE_CAN_BE_DEPRECATED = false

    def self.platforms
      @platforms ||= begin
        Dir[Rails.root.join('app', 'models', 'package_manager', '*.rb')].each do |file|
          require file unless file.match(/base\.rb$/)
        end
        PackageManager.constants
          .reject { |platform| platform == :Base }
          .map{|sym| "PackageManager::#{sym}".constantize }
          .reject { |platform| platform::HIDDEN }
          .sort_by(&:name)
      end
    end

    def self.default_language
      Linguist::Language.all.find{|l| l.color == color }.try(:name)
    end

    def self.format_name(platform)
      return nil if platform.nil?
      find(platform).to_s.demodulize
    end

    def self.find(platform)
      platforms.find{|p| p.formatted_name.downcase == platform.downcase }
    end

    def self.color
      self::COLOR
    end

    def self.homepage
      self::URL
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

    def self.download_registry_users(_name)
      nil
    end

    def self.registry_user_url(_login)
      nil
    end

    def self.check_status_url(project)
      package_link(project)
    end

    def self.platform_name(platform)
      find(platform).try(:formatted_name) || platform
    end

    def self.save(project)
      return unless project.present?
      mapped_project = mapping(project)
      mapped_project = mapped_project.delete_if { |_key, value| value.blank? } if mapped_project.present?
      return false unless mapped_project.present?
      dbproject = Project.find_or_initialize_by({:name => mapped_project[:name], :platform => self.name.demodulize})
      if dbproject.new_record?
        dbproject.assign_attributes(mapped_project.except(:name, :releases, :versions, :version, :dependencies, :properties))
        dbproject.save
      else
        dbproject.reformat_repository_url
        attrs = mapped_project.except(:name, :releases, :versions, :version, :dependencies, :properties)
        dbproject.update_attributes(attrs)
      end

      if self::HAS_VERSIONS
        versions(project).each do |version|
          unless dbproject.versions.find {|v| v.number == version[:number] }
            dbproject.versions.create(version)
          end
        end
      end

      if self::HAS_DEPENDENCIES
        save_dependencies(mapped_project)
      end
      dbproject.reload
      dbproject.download_registry_users
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
      return if ENV['READ_ONLY'].present?
      project_names.each { |name| update(name) }
    end

    def self.import_recent
      return if ENV['READ_ONLY'].present?
      recent_names.each { |name| update(name) }
    end

    def self.import_new
      return if ENV['READ_ONLY'].present?
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
      proj.versions.includes(:dependencies).each do |version|
        next if version.dependencies.any?
        deps = dependencies(name, version.number, mapped_project) rescue []
        next unless deps && deps.any? && version.dependencies.empty?
        deps.each do |dep|
          unless dep[:project_name].blank? || version.dependencies.find_by_project_name(dep[:project_name])

            named_project_id = Project
              .find_best(self.name.demodulize, dep[:project_name].strip)
              &.id
            version.dependencies.create(dep.merge(project_id: named_project_id.try(:strip)))
          end
        end
        version.set_runtime_dependencies_count
      end
    end

    def self.dependencies(_name, _version, _project)
      []
    end

    def self.map_dependencies(deps, kind, optional = false, platform = self.name.demodulize)
      deps.map do |k,v|
        {
          project_name: k,
          requirements: v,
          kind: kind,
          optional: optional,
          platform: platform
        }
      end
    end

    def self.find_and_map_dependencies(name, version, _project)
      dependencies = find_dependencies(name, version)
      return [] unless dependencies && dependencies.any?
      dependencies.map do |dependency|
        dependency = dependency.deep_stringify_keys
        {
          project_name: dependency["name"],
          requirements: dependency["requirement"] || '*',
          kind: dependency["type"],
          platform: self.name.demodulize
        }
      end
    end

    def self.repo_fallback(repo, homepage)
      repo = '' if repo.nil?
      homepage = '' if homepage.nil?
      repo_url = URLParser.try_all(repo)
      homepage_url = URLParser.try_all(homepage)
      if repo_url.present?
        return repo_url
      elsif homepage_url.present?
        return homepage_url
      else
        repo
      end
    end

    def self.project_find_names(project_name)
      [project_name]
    end

    def self.entire_package_deprecation_info(name)
      { is_deprecated: false, message: nil }
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
        builder.request :retry, { max: 2, interval: 0.05, interval_randomness: 0.5, backoff_factor: 2 }
        
        builder.use :instrumentation
        builder.adapter :typhoeus
      end
      connection.get
    end

    def self.get_html(url, options = {})
      Nokogiri::HTML(get_raw(url, options))
    end

    def self.get_xml(url, options = {})
      Ox.parse(get_raw(url, options))
    end

    def self.get_json(url)
      get(url, headers: { 'Accept' => "application/json"})
    end

    def self.download_async(names)
      names.each { |name| PackageManagerDownloadWorker.perform_async(self.name.demodulize, name) }
    end
  end
end
