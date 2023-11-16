# frozen_string_literal: true

module PackageManager
  class Base
    COLOR = "#fff"
    BIBLIOTHECARY_SUPPORT = false
    BIBLIOTHECARY_PLANNED = false
    HAS_MULTIPLE_REPO_SOURCES = false
    SECURITY_PLANNED = false
    HIDDEN = false
    SYNC_ACTIVE = true
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
          # Only platform managers will have the HIDDEN constant set
          .find_all { |platform| platform.const_defined?(:HIDDEN) && platform.const_get(:HIDDEN) == false }
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

    def self.package_link(_db_project, _version = nil)
      nil
    end

    def self.download_url(_db_project, _version = nil)
      nil
    end

    def self.documentation_url(_name, _version = nil)
      nil
    end

    def self.install_instructions(_db_project, _version = nil)
      nil
    end

    def self.download_registry_users(_name)
      nil
    end

    def self.registry_user_url(_login)
      nil
    end

    def self.check_status_url(db_project)
      package_link(db_project)
    end

    def self.platform_name(platform)
      find(platform).try(:formatted_name) || platform
    end

    private_class_method def self.transform_mapping_values(mapping)
      mapping.try do |p|
        p.compact.transform_values { |v| v.is_a?(String) ? v.gsub("\u0000", "") : v }
      end
    end

    private_class_method def self.ensure_project(mapped_project, reformat_repository_url: false)
      db_project = Project.find_or_initialize_by({ name: mapped_project[:name], platform: db_platform })
      db_project.reformat_repository_url if reformat_repository_url && !db_project.new_record?
      mapped_project[:repository_url] = db_project.repository_url if mapped_project[:repository_url].blank?
      db_project.attributes = mapped_project.except(:name, :releases, :versions, :version, :dependencies, :properties)

      begin
        db_project.save!
      rescue ActiveRecord::RecordInvalid => e
        raise e unless e.message =~ /Name has already been taken/

        # Probably a race condition with multiple versions of a new project being updated.
        db_project = Project.find_by(platform: db_platform, name: mapped_project[:name])
      end

      db_project
    end

    def self.update(name, sync_version: :all, force_sync_dependencies: false)
      if sync_version != :all && !self::SUPPORTS_SINGLE_VERSION_UPDATE
        Rails.logger.warn("#{db_platform}.update(#{name}, sync_version: #{sync_version}) called but not supported on platform")
        return
      end

      raw_project = project(name)
      return false unless raw_project.present?

      mapped_project = transform_mapping_values(mapping(raw_project))
      return false unless mapped_project.present?

      db_project = ensure_project(mapped_project, reformat_repository_url: sync_version == :all)

      if self::HAS_VERSIONS
        if sync_version == :all
          versions_as_version_objects(raw_project, db_project.name)
            .each { |v| add_version(db_project, v) }
            .tap { |vs| remove_missing_versions(db_project, vs) }
        elsif (version = one_version_as_version_object(raw_project, sync_version))
          add_version(db_project, version)
          # TODO: handle deprecation here too
        end
      end

      save_dependencies(mapped_project, sync_version: sync_version, force_sync_dependencies: force_sync_dependencies) if self::HAS_DEPENDENCIES
      finalize_db_project(db_project)
    end

    def self.versions_as_version_objects(raw_project, name)
      raw_versions = versions(raw_project, name)

      raw_versions.each_with_object([]) do |version_hash, obj|
        # preserve blanks to fit behavior of add_version
        # TODO: change this behavior
        if version_hash.blank?
          obj << version
          next
        end

        obj << version_hash_to_version_object(version_hash)
      end
    end

    def self.one_version_as_version_object(raw_project, sync_version)
      version_hash = one_version(raw_project, sync_version)

      return version_hash if version_hash.blank?

      version_hash_to_version_object(version_hash)
    end

    def self.version_hash_to_version_object(version_hash)
      version_hash = version_hash.symbolize_keys

      ApiVersion.new(
        version_number: version_hash[:number],
        published_at: version_hash[:published_at],
        runtime_dependencies_count: version_hash[:runtime_dependencies_count],
        original_license: version_hash[:original_license],
        repository_sources: version_hash[:repository_sources],
        status: version_hash[:status]
      )
    end

    def self.add_version(db_project, api_version)
      return if api_version.blank?

      new_repository_source = self::HAS_MULTIPLE_REPO_SOURCES ? self::REPOSITORY_SOURCE_NAME : nil

      VersionUpdater.new(
        project: db_project,
        api_version_to_upsert: api_version,
        new_repository_source: new_repository_source
      ).upsert_version_for_project!
    end

    def self.missing_version_remover
      nil
    end

    def self.remove_missing_versions(db_project, api_versions)
      return unless missing_version_remover

      # yanked pypi versions are marked as such in the api, and the majority of them are handled upstream of here
      # TODO: if libraries knows about the version but pypi does not, also mark the version differences as removed

      missing_version_remover.new(
        project: db_project,
        version_numbers_to_keep: api_versions.map(&:version_number),
        target_status: "Removed",
        removal_time: Time.zone.now
      ).remove_missing_versions_of_project!
    end

    def self.finalize_db_project(db_project)
      db_project.reload
      db_project.download_registry_users
      db_project.update!(last_synced_at: Time.now)
      db_project.try(:update_repository_async)
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

    def self.save_dependencies(mapped_project, sync_version: :all, force_sync_dependencies: false)
      name = mapped_project[:name]
      db_project = Project.find_by(name: name, platform: db_platform)
      db_versions = db_project.versions.includes(:dependencies)
      db_versions = db_versions.where(number: sync_version) unless sync_version == :all

      if db_versions.empty?
        StructuredLog.capture("SAVE_DEPENDENCIES_FAILURE", { platform: db_platform, name: name, version: sync_version, message: "no versions found" })
      end

      db_versions.each do |db_version|
        next if db_version.dependencies.any? && !force_sync_dependencies

        deps = begin
          dependencies(name, db_version.number, mapped_project)
        rescue StandardError => e
          Rails.logger.error(
            "Error while trying to get dependencies for #{db_platform}/#{name}@#{db_version.number}: #{e.message}"
          )
          []
        end

        # if we are forcing a resync of the dependencies in here then wipe out existing ones
        # so that we have the fresh and correct dependency information from the most recent
        # call to dependencies() from the platform provider
        if force_sync_dependencies
          Rails.logger.info("[Full Dependency Refresh] platform=#{db_platform} name=#{name} version=#{db_version.number}")
          db_version.dependencies.destroy_all
        end

        deps.each do |dep|
          next if dep[:project_name].blank? || dep[:requirements].blank? || db_version.dependencies.any? { |d| d.project_name == dep[:project_name] }

          named_project_id = Project
            .find_best(db_platform, dep[:project_name].strip)
            &.id
          db_version.dependencies.create!(dep.merge(project_id: named_project_id.try(:strip)))
        end
        db_version.set_runtime_dependencies_count if deps.any?
        db_version.set_dependencies_count # this serves as a marker that we have saved Version#dependencies or not, even if there are zero (other)
      end
    end

    def self.dependencies(_name, _version, _mapped_project)
      []
    end

    def self.map_dependencies(deps, kind, optional: false, platform: db_platform)
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

    def self.find_and_map_dependencies(name, version, _mapped_project)
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
      RepositoryService.repo_fallback(repo, homepage)
    end

    def self.project_find_names(project_name)
      [project_name]
    end

    def self.deprecation_info(_db_project)
      { is_deprecated: false, message: nil }
    end

    private_class_method def self.get(url, options = {})
      ApiService.request_and_parse_json(url, options)
    end

    private_class_method def self.get_raw(url, options = {})
      ApiService.request_raw_data(url, options)
    end

    private_class_method def self.request(url, options = {})
      ApiService.make_retriable_request(url, options)
    end

    private_class_method def self.get_html(url, options = {})
      ApiService.request_and_parse_html(url, options)
    end

    private_class_method def self.get_xml(url, options = {})
      ApiService.request_and_parse_xml(url, options)
    end

    private_class_method def self.get_json(url)
      ApiService.request_json_with_headers(url)
    end

    private_class_method def self.download_async(names)
      if SYNC_ACTIVE != true
        logger.info("Skipping Package update for inactive platform=#{platform_name} names=#{names.join(',')}")
        return
      end

      names.each_slice(1000).with_index do |group, index|
        group.each { |name| PackageManagerDownloadWorker.perform_in(index.hours, self.name, name, nil, "download_async") }
      end
    end
  end
end
