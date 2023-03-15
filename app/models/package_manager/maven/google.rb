# frozen_string_literal: true

class PackageManager::Maven::Google < PackageManager::Maven::Common
  REPOSITORY_SOURCE_NAME = "Google"
  SUPPORTS_SINGLE_VERSION_UPDATE = true
  HIDDEN = true

  def self.repository_base
    "https://dl.google.com/dl/android/maven2"
  end

  def self.project_names
    []
  end

  def self.recent_names
    get("https://maven.libraries.io/googleMaven/recent")
  end

  # TODO: check and store if the value on the other end is a JAR or AAR file
  # This returns a link to the Google Maven docs where the JAR or AAR
  # file can be downloaded.
  def self.download_url(db_project, version = nil)
    if version
      "https://maven.google.com/web/index.html##{db_project.name}:#{version}"
    else
      "https://maven.google.com/web/index.html##{db_project.name}"
    end
  end

  def self.update(
    name, sync_version:
  )
    raw_project = project(
      name,
      latest: latest_version(name)
    )

    mapped_project = transform_mapping_values(mapping(raw_project))
    return false unless mapped_project.present?

    db_project = ensure_project(mapped_project, reformat_repository_url: true)

    version_hash = one_version_for_name(sync_version, name)

    add_version(db_project, version_hash)

    finalize_db_project(db_project)
  end

  def self.latest_version(name)
    group_name, artifact = name.split(NAME_DELIMITER)

    group_path = group_name.gsub(".", "/")

    packages = Nokogiri::XML(get_raw("https://maven.google.com/#{group_path}/group-index.xml")).root.children.find_all(&:element?)

    packages.each do |package|
      package_name = package.name

      next unless package_name == artifact

      versions = package["versions"].split(",")

      return versions.last
    end

    nil
  end

  # This is called by the Rake task maven:populate_google_maven.
  # It lives here because re-creating all of the PackageManager-specific
  # code in the Rake task itself would be unreasonable to do.
  def self.update_all_versions
    main = Nokogiri::XML(get_raw("https://maven.google.com/master-index.xml"))

    main.css("metadata").children.find_all(&:element?).each do |group|
      group_name = group.name

      group_path = group_name.gsub(".", "/")

      packages = Nokogiri::XML(get_raw("https://maven.google.com/#{group_path}/group-index.xml")).root.children.find_all(&:element?)

      packages.each do |package|
        package_name = package.name

        versions = package["versions"].split(",")

        name = [group_name, package_name].join(PackageManager::Maven::NAME_DELIMITER)

        raw_project = project(
          name,
          latest: versions.last # not totally accurate but it's all we have at this point
        )

        mapped_project = transform_mapping_values(mapping(raw_project))
        return false unless mapped_project.present?

        db_project = ensure_project(mapped_project, reformat_repository_url: true)

        pp "added project #{name}"

        versions.each do |version|
          version_hash = one_version_for_name(version, name)

          add_version(db_project, version_hash)

          pp "added version #{version}"
        rescue Faraday::ConnectionFailed
          retry
        end

        finalize_db_project(db_project)
      rescue Faraday::ConnectionFailed
        retry
      end

      sleep 5
    rescue Faraday::ConnectionFailed
      retry
    end
  end
end
