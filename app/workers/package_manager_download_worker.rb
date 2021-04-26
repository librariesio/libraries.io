# frozen_string_literal: true

class PackageManagerDownloadWorker
  include Sidekiq::Worker
  sidekiq_options queue: :critical

  PLATFORMS = {
    alcatraz: PackageManager::Alcatraz,
    atom: PackageManager::Atom,
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
    emacs: PackageManager::Emacs,
    go: PackageManager::Go,
    hackage: PackageManager::Hackage,
    haxelib: PackageManager::Haxelib,
    hex: PackageManager::Hex,
    homebrew: PackageManager::Homebrew,
    inqlude: PackageManager::Inqlude,
    jam: PackageManager::Jam,
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
    platformio: PackageManager::PlatformIO,
    pub: PackageManager::Pub,
    puppet: PackageManager::Puppet,
    purescript: PackageManager::PureScript,
    pypi: PackageManager::Pypi,
    racket: PackageManager::Racket,
    rubygems: PackageManager::Rubygems,
    shards: PackageManager::Shards,
    sublime: PackageManager::Sublime,
    swiftpm: PackageManager::SwiftPM,
    wordpress: PackageManager::Wordpress,
  }.freeze

  def perform(platform_name, name, version = nil)
    key, platform = get_platform(platform_name)
    name = name.to_s.strip
    version = version.to_s.strip
    sync_version = (platform::SUPPORTS_SINGLE_VERSION_UPDATE && version.presence) || :all

    logger.info("Package update for platform=#{key} name=#{name} version=#{version}")
    project = platform.update(name, sync_version: sync_version)

    # Raise exception if version was requested but not found
    raise("PackageManagerDownloadWorker version update fail platform=#{key} name=#{name} version=#{version}") if version.present? && !Version.exists?(project: project, number: version)
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
