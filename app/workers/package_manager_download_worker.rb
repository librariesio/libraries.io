# frozen_string_literal: true

class PackageManagerDownloadWorker
  include Sidekiq::Worker

  # For stale repo pages without fresh versions, we have a manual retry mechanism
  # below. All other errors retry 3 times.
  sidekiq_options queue: :critical, retry: 3

  # We were unable to fetch version, even after waiting for repo caches to refresh.
  class VersionUpdateFailure < StandardError
    def initialize(platform, name, version)
      super("Could not find release platform=#{platform} name=#{name} version=#{version}")
    end
  end

  MAX_ATTEMPTS_TO_UPDATE_FRESH_VERSION_DATA = 15

  PLATFORMS = {
    alcatraz: PackageManager::Alcatraz,
    biicode: PackageManager::Biicode,
    bower: PackageManager::Bower,
    cargo: PackageManager::Cargo,
    carthage: PackageManager::Carthage,
    clojars: PackageManager::Clojars,
    cocoapods: PackageManager::CocoaPods,
    conda: PackageManager::Conda,
    conda_main: PackageManager::Conda::Main,
    conda_forge: PackageManager::Conda::Forge,
    cpan: PackageManager::CPAN,
    cran: PackageManager::CRAN,
    dub: PackageManager::Dub,
    elm: PackageManager::Elm,
    go: PackageManager::Go,
    hackage: PackageManager::Hackage,
    haxelib: PackageManager::Haxelib,
    hex: PackageManager::Hex,
    homebrew: PackageManager::Homebrew,
    inqlude: PackageManager::Inqlude,
    julia: PackageManager::Julia,
    maven: PackageManager::Maven,
    maven_atlassian: PackageManager::Maven::Atlassian,
    maven_hortonworks: PackageManager::Maven::Hortonworks,
    maven_mavencentral: PackageManager::Maven::MavenCentral,
    maven_springlibs: PackageManager::Maven::SpringLibs,
    maven_jboss: PackageManager::Maven::Jboss,
    maven_jbossea: PackageManager::Maven::JbossEa,
    maven_google: PackageManager::Maven::Google,
    meteor: PackageManager::Meteor,
    nimble: PackageManager::Nimble,
    npm: PackageManager::NPM,
    nuget: PackageManager::NuGet,
    packagist: PackageManager::Packagist,
    packagist_drupal: PackageManager::Packagist::Drupal,
    packagist_main: PackageManager::Packagist::Main,
    pub: PackageManager::Pub,
    puppet: PackageManager::Puppet,
    purescript: PackageManager::PureScript,
    pypi: PackageManager::Pypi,
    racket: PackageManager::Racket,
    rubygems: PackageManager::Rubygems,
    swiftpm: PackageManager::SwiftPM,
  }.freeze

  # rubocop: disable Style/OptionalBooleanParameter
  # rubocop: disable Metrics/ParameterLists
  def perform(platform_name, name, version = nil, source = "unknown", requeue_count = 0, force_sync_dependencies = false)
    key, package_manager = package_manager_for_platform(platform_name)
    name = name.to_s.strip
    version = version.to_s.strip
    sync_version = (package_manager.supports_single_version_update? && version.presence) || :all

    if package_manager::SYNC_ACTIVE != true
      Rails.logger.info("Skipping Package update for inactive platform=#{key} name=#{name} version=#{version} source=#{source}")
      return
    end

    Rails.logger.info("Package update for platform=#{key} name=#{name} version=#{version} source=#{source}")
    project = package_manager.update(name, sync_version: sync_version, force_sync_dependencies: force_sync_dependencies, source: source)

    # Raise/log if version was requested but not found
    if version.present? && project && !project&.versions&.exists?(number: version)
      Rails.logger.info("[Version Update Failure] platform=#{key} name=#{name} version=#{version}")

      if requeue_count < MAX_ATTEMPTS_TO_UPDATE_FRESH_VERSION_DATA
        PackageManagerDownloadWorker.perform_in(5.seconds, platform_name, name, version, source, requeue_count + 1, force_sync_dependencies)
      elsif package_manager != PackageManager::Go
        # It's common for go modules, e.g. forks, to not exist on pkg.go.dev, so wait until someone
        # manually requests it from pkg.go.dev before we index it, and only raise this error for non-go packages.
        raise VersionUpdateFailure.new(package_manager.db_platform, name, version)
      end
    end
  end
  # rubocop: enable Style/OptionalBooleanParameter
  # rubocop: enable Metrics/ParameterLists

  private

  def package_manager_for_platform(platform_name)
    key = begin
      platform_name
        .gsub(/PackageManager::/, "")
        .gsub(/::/, "_")
        .downcase
        .to_sym
    rescue StandardError
      nil
    end

    return key, PLATFORMS[key] if PLATFORMS.key?(key)

    raise("Platform '#{platform_name}' not found")
  end
end
