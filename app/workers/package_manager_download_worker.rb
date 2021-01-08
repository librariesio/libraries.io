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

  def perform(platform_name, name)
    platform = PLATFORMS[platform_name&.downcase&.to_sym]
    raise "Platform '#{platform_name}' not found" unless platform

    # need to maintain compatibility with things that pass in the name of the class under PackageManager module
    logger.info("Beginning update for #{platform.to_s.demodulize}/#{name}")
    platform.update(name)
  end
end
