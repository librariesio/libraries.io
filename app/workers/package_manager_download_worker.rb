# frozen_string_literal: true

class PackageManagerDownloadWorker
  include Sidekiq::Worker
  
  # For stale repo pages without fresh versions, we have a manual retry mechanism 
  # below. All other errors retry 3 times. 
  sidekiq_options queue: :critical, retry: 3

  # We were unable to fetch version, even after waiting for repo caches to refresh.
  class VersionUpdateFailure < StandardError; end

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

  def perform(platform_name, name, version = nil, source = "unknown", requeue_count = 0)
    key, platform = get_platform(platform_name)
    name = name.to_s.strip
    version = version.to_s.strip
    sync_version = (platform::SUPPORTS_SINGLE_VERSION_UPDATE && version.presence) || :all

    logger.info("Package update for platform=#{key} name=#{name} version=#{version} source=#{source}")
    project = platform.update(name, sync_version: sync_version)

    # Raise/log if version was requested but not found
    if version.present? && !Version.exists?(project: project, number: version)
      Rails.logger.info("[Version Update Failure] platform=#{key} name=#{name} version=#{version}")
      if requeue_count < MAX_ATTEMPTS_TO_UPDATE_FRESH_VERSION_DATA
        PackageManagerDownloadWorker.perform_in(5.seconds, platform_name, name, version, source, requeue_count + 1)
      elsif platform != PackageManager::Go
        # It's common for go modules, e.g. forks, to not exist on pkg.go.dev, so wait until someone
        # manually requests it from pkg.go.dev before we index it, and only raise this error for non-go packages.
        raise VersionUpdateFailure
      end
    end
  end

  def get_platform(platform_name)
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
