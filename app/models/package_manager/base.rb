# frozen_string_literal: true

module PackageManager
  class Base
    COLOR = "#fff"
    BIBLIOTHECARY_SUPPORT = false
    BIBLIOTHECARY_PLANNED = false
    HAS_MULTIPLE_REPO_SOURCES = false
    SECURITY_PLANNED = false
    HIDDEN = false
    HAS_OWNERS = false
    ENTIRE_PACKAGE_CAN_BE_DEPRECATED = false
    SUPPORTS_SINGLE_VERSION_UPDATE = false

    def self.platforms
      @platforms ||= begin
        Dir[Rails.root.join("app", "models", "package_manager", "*.rb")].sort.each do |file|
          require file unless file.match(/base\.rb$/)
        end
        PackageManager.constants
          .reject { |platform| platform == :Base }
          .map { |sym| "PackageManager::#{sym}".constantize }
          .reject { |platform| platform::HIDDEN }
          .sort_by(&:name)
      end
    end

    def self.default_language
      Linguist::Language.all.find { |l| l.color == color }.try(:name)
    end

    def self.format_name(platform)
      return nil if platform.nil?

      find(platform).to_s.demodulize
    end

    def self.find(platform)
      platforms.find { |p| p.formatted_name.downcase == platform.downcase }
    end

    def self.db_platform
      name.demodulize
    end

    def self.color
      self::COLOR
    end

    def self.homepage
      self::URL
    end

    def self.formatted_name
      to_s.demodulize
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

    def self.map_project(project)
      mapping(project)
        &.delete_if { |_key, value| value.blank? }
    end

    def self.update(name, sync_version: :all)
      if sync_version != :all && !self::SUPPORTS_SINGLE_VERSION_UPDATE
        logger.warn("#{db_platform}.update(#{name}, sync_version: #{sync_version}) called but not supported on platform")
        return
      end

      raw_project = project(name)
      return false unless raw_project.present?

      mapped_project = map_project(raw_project)
      return false unless mapped_project.present?

      db_project = Project.find_or_initialize_by({ name: mapped_project[:name], platform: db_platform })
      db_project.reformat_repository_url if sync_version == :all && !db_project.new_record?
      db_project.update!(mapped_project.except(:name, :releases, :versions, :version, :dependencies, :properties))

      if self::HAS_VERSIONS
        if sync_version == :all
          versions(raw_project, db_project.name)
            .each { |v| add_version(db_project, v) }
            .tap { |vs| deprecate_versions(db_project, vs) }
        else
          add_version(db_project, one_version(db_project.name, sync_version))
          # TODO handle deprecation here too
        end
      end

      save_dependencies(mapped_project) if self::HAS_DEPENDENCIES
      finalize_db_project(db_project)
    rescue StandardError => e
      if ENV["RACK_ENV"] == "production"
        Bugsnag.notify(e)
      else
        raise
      end
    end

    def self.add_version(db_project, version_hash)
      existing = db_project.versions.find_or_initialize_by(number: version_hash[:number]) do |new_version|
        new_version.assign_attributes version_hash
      end
      existing.repository_sources = Set.new(existing.repository_sources).add(self::REPOSITORY_SOURCE_NAME).to_a if self::HAS_MULTIPLE_REPO_SOURCES
      existing.save!
    end

    def self.deprecate_versions(db_project, version_hash)
      case db_project.platform.downcase
      when "rubygems" # yanked gems will be omitted from project JSON versions
        db_project
          .versions
          .where.not(number: version_hash.pluck(:number))
          .update_all(status: "Removed")
      end
    end

    def self.finalize_db_project(db_project)
      db_project.reload
      db_project.download_registry_users
      db_project.update!(last_synced_at: Time.now)
      db_project
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
      return if ENV["READ_ONLY"].present?

      project_names.each { |name| update(name) }
    end

    def self.import_recent
      return if ENV["READ_ONLY"].present?

      recent_names.each { |name| update(name) }
    end

    def self.import_new
      return if ENV["READ_ONLY"].present?

      new_names.each { |name| update(name) }
    end

    def self.new_names
      names = project_names
      existing_names = []
      Project.platform(db_platform).select(:id, :name).find_each { |project| existing_names << project.name }
      names - existing_names
    end

    def self.save_dependencies(mapped_project)
      name = mapped_project[:name]
      db_project = Project.find_by(name: name, platform: db_platform)
      db_project.versions.includes(:dependencies).each do |db_version|
        next if db_version.dependencies.any?

        deps = begin
                 dependencies(name, db_version.number, mapped_project)
               rescue StandardError
                 []
               end

        deps.each do |dep|
          next if dep[:project_name].blank? || dep[:requirements].blank? || db_version.dependencies.any? { |d| d.project_name == dep[:project_name] }

          named_project_id = Project
            .find_best(db_platform, dep[:project_name].strip)
            &.id
          db_version.dependencies.create!(dep.merge(project_id: named_project_id.try(:strip)))
        end
        db_version.set_runtime_dependencies_count if deps.any?
      end
    end

    def self.dependencies(_name, _version, _project)
      []
    end

    def self.map_dependencies(deps, kind, optional = false, platform = db_platform)
      deps.map do |k, v|
        {
          project_name: k,
          requirements: v,
          kind: kind,
          optional: optional,
          platform: platform,
        }
      end
    end

    def self.find_and_map_dependencies(name, version, _project)
      dependencies = find_dependencies(name, version)
      return [] unless dependencies&.any?

      dependencies.map do |dependency|
        dependency = dependency.deep_stringify_keys
        {
          project_name: dependency["name"],
          requirements: dependency["requirement"] || "*",
          kind: dependency["type"],
          platform: db_platform,
        }
      end
    end

    def self.repo_fallback(repo, homepage)
      repo = "" if repo.nil?
      homepage = "" if homepage.nil?
      repo_url = URLParser.try_all(repo)
      homepage_url = URLParser.try_all(homepage)
      if repo_url.present?
        repo_url
      elsif homepage_url.present?
        homepage_url
      else
        repo
      end
    end

    def self.project_find_names(project_name)
      [project_name]
    end

    def self.deprecation_info(_name)
      { is_deprecated: false, message: nil }
    end

    private_class_method def self.get(url, options = {})
      Oj.load(get_raw(url, options))
    end

    private_class_method def self.get_raw(url, options = {})
      rsp = request(url, options)
      return "" unless rsp.status == 200
      return rsp.body
    end

    private_class_method def self.request(url, options = {})
      connection = Faraday.new url.strip, options do |builder|
        builder.use FaradayMiddleware::Gzip
        builder.use FaradayMiddleware::FollowRedirects, limit: 3
        builder.request :retry, { max: 2, interval: 0.05, interval_randomness: 0.5, backoff_factor: 2 }

        builder.use :instrumentation
        builder.adapter :typhoeus
      end
      connection.get
    end

    private_class_method def self.get_html(url, options = {})
      Nokogiri::HTML(get_raw(url, options))
    end

    private_class_method def self.get_xml(url, options = {})
      Ox.parse(get_raw(url, options))
    end

    private_class_method def self.get_json(url)
      get(url, headers: { "Accept" => "application/json" })
    end

    private_class_method def self.download_async(names)
      names.each_slice(1000).each_with_index do |group, index|
        group.each { |name| PackageManagerDownloadWorker.perform_in(index.hours, self.name, name) }
      end
    end
  end
end
