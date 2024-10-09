# frozen_string_literal: true

module PackageManager
  # Package Managers retrieve information about an entire package, or a
  # specific release of a pacakge. This retrieval can be triggered via
  # asynchronous jobs, or directly by API endpoints or the console.
  class Base
    class MethodNotImplementedError < StandardError; end

    COLOR = "#fff"
    BIBLIOTHECARY_SUPPORT = false
    BIBLIOTHECARY_PLANNED = false
    HAS_MULTIPLE_REPO_SOURCES = false
    SECURITY_PLANNED = false
    HIDDEN = false
    SYNC_ACTIVE = true
    HAS_OWNERS = false
    ENTIRE_PACKAGE_CAN_BE_DEPRECATED = false

    def self.platforms
      @platforms ||= begin
        Dir[Rails.root.join("app", "models", "package_manager", "*.rb")].each do |file|
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

    private_class_method def self.ensure_project(mapped_project, reformat_repository_url: false)
      db_project = Project.find_or_initialize_by({ name: mapped_project[:name], platform: db_platform })
      db_project.reformat_repository_url if reformat_repository_url && !db_project.new_record?
      db_project.attributes = mapped_project.except(:name, :versions, :version, :dependencies, :properties)

      begin
        db_project.save!
      rescue ActiveRecord::RecordInvalid => e
        raise e unless e.message =~ /Name has already been taken/

        # Probably a race condition with multiple versions of a new project being updated.
        db_project = Project.find_by(platform: db_platform, name: mapped_project[:name])
      end

      db_project
    end

    # Override this in a subclass if you need to temporarily disable single version
    # updates on a class that supports them.
    def self.supports_single_version_update?
      respond_to?(:one_version)
    end

    # Single version updates, when supported, reduce database and Sidekiq
    # utilization. To support single version update in a package manager,
    # add a class method to the package manager called `one_version`.
    # It should return a Hash of:
    #
    # {
    #   number: <version number>,
    #   published_at: <Time version was published>,
    #   original_license: <License string from upstream>
    # }
    def self.update(name, sync_version: :all, force_sync_dependencies: false, source: nil)
      if sync_version != :all && !supports_single_version_update?
        Rails.logger.warn("#{db_platform}.update(#{name}, sync_version: #{sync_version}) called but not supported on platform")
        return
      end

      raw_project = project(name)
      return false unless raw_project.present?

      mapped_project = mapping(raw_project)
      return false unless mapped_project.present?

      db_project = ensure_project(mapped_project, reformat_repository_url: sync_version == :all)

      if self::HAS_VERSIONS
        if sync_version == :all
          version_objects = versions_as_version_objects(raw_project, db_project.name)
          preloaded_db_versions = db_project.versions.where(number: version_objects.map(&:version_number))
          version_objects
            .each { |v| add_version(db_project, v, preloaded_db_versions) }
            .tap { |vs| remove_missing_versions(db_project, vs) }
        elsif (version = one_version_as_version_object(raw_project, sync_version))
          preloaded_db_versions = db_project.versions.where(number: version.version_number)
          add_version(db_project, version, preloaded_db_versions)
          # TODO: handle deprecation here too
        end
      end

      save_dependencies(mapped_project, sync_version: sync_version, force_sync_dependencies: force_sync_dependencies, source: source) if self::HAS_DEPENDENCIES
      finalize_db_project(db_project)
    end

    # Override this in the subclass to fetch the raw data from the upstream
    # package manager. This can be any arbitrary data, and will passed on to the
    # mapping() method to get a standard shape of data.
    def self.project(_name)
      raise MethodNotImplementedError
    end

    # Override this in the subclass to map the raw data from project() to
    # a Hash of data that we'll need to save Project and Version records.
    # Use the PackageManager::MappingBuilder to create the Hash.
    #
    # @return [Hash{Symbol => Any}] Libraries' common package data fields, mapped
    # from the api response. Keys are defined in MappingBuilder.
    def self.mapping(_raw_project)
      raise MethodNotImplementedError
    end

    # Returns the versions found within the raw project data for the package.
    # Depending on the package manager, additional work may need to be done to
    # retrieve all the information to pass into
    # version_hash_to_version_object.
    def self.versions(_raw_project, _name)
      raise MethodNotImplementedError
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

    # Data coming from versions or one_version need to conform to the
    # hash structure within.
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

    def self.add_version(db_project, api_version, preloaded_db_versions)
      return if api_version.blank?

      new_repository_source = self::HAS_MULTIPLE_REPO_SOURCES ? self::REPOSITORY_SOURCE_NAME : nil

      VersionUpdater.new(
        project: db_project,
        api_version_to_upsert: api_version,
        new_repository_source: new_repository_source,
        preloaded_db_versions: preloaded_db_versions
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

    def self.save_dependencies(mapped_project, sync_version: :all, force_sync_dependencies: false, source: nil)
      name = mapped_project[:name]
      db_project = Project.find_by(name: name, platform: db_platform)

      db_versions = db_project.versions
      db_versions = db_versions.where(number: sync_version) unless sync_version == :all
      # Do preloads in batches of 200 versions, because we don't want a big preload query that
      # queries on thousands of Version ids, especially when each Version could have thousands
      # of Dependencies.
      db_versions = db_versions.in_batches(of: 200).map { |vs| vs.includes(:dependencies) }.flatten

      # cached lookup of dependency platform/names => project ids, so we avoid repetitive project lookups in find_best! below.
      platform_and_names_to_project_ids = {}

      if db_versions.empty?
        StructuredLog.capture("SAVE_DEPENDENCIES_FAILURE", { platform: db_platform, name: name, version: sync_version, message: "no versions found", source: source })
      end

      db_versions.each do |db_version|
        next if !db_version.dependencies_count.nil? && !force_sync_dependencies

        deps = begin
          dependencies(name, db_version.number, mapped_project)
        rescue StandardError => e
          StructuredLog.capture("SAVE_DEPENDENCIES_FAILURE", { platform: db_platform, name: name, version: db_version.number, message: "error getting dependencies: #{e.message}", source: source })
          []
        end

        # if we are forcing a resync of the dependencies in here then wipe out existing ones
        # so that we have the fresh and correct dependency information from the most recent
        # call to dependencies() from the platform provider
        if force_sync_dependencies
          StructuredLog.capture("SAVE_DEPENDENCIES_FULL_REFRESH", { platform: db_platform, name: name, version: db_version.number, source: source })
          db_version.dependencies.destroy_all
        end

        existing_dep_names = db_version.dependencies.map(&:project_name)

        new_dep_attributes = deps
          .reject { |dep| existing_dep_names.include?(dep[:project_name]) }
          .map do |dep|
            dep_platform_and_name = [db_platform, dep[:project_name].to_s.strip]
            named_project_id = if platform_and_names_to_project_ids.key?(dep_platform_and_name)
                                 platform_and_names_to_project_ids[dep_platform_and_name]
                               else
                                 platform_and_names_to_project_ids[dep_platform_and_name] = Project.find_best(db_platform, dep[:project_name].to_s.strip)&.id
                               end

            dep.merge(version_id: db_version.id, project_id: named_project_id)
          end

        # Validate the new dependencies before performing the upsert
        new_dep_attributes.each do |attrs|
          dependency = Dependency.new(attrs)
          dependency.validate!
        rescue ActiveRecord::RecordInvalid => e
          # If we don't have a valid dependency to upsert, log it, and fail noisily
          message = dependency.errors.full_messages.join(", ").gsub(/'/, "")
          StructuredLog.capture("SAVE_DEPENDENCIES_FAILURE", { platform: db_platform, name: name, version: db_version, dependency_name: dependency.project_name, message: message, source: source })
          raise e
        end

        # bulk insert all the Dependencies for the Version: note that as of writing there are no unique indices on Dependency, so any de-duping
        # was done in the reject() above. So doing an upsert here would be pointless which is why we only do a bulk insert.
        Dependency.insert_all(new_dep_attributes) unless new_dep_attributes.empty?

        # this serves as a marker that we have saved Version#dependencies or not, even if there are zero (other)
        db_version.set_runtime_dependencies_count
        db_version.set_dependencies_count
      end

      db_project.set_dependents_count_async
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
