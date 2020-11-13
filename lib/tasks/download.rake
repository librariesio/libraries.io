# frozen_string_literal: true

namespace :download do
  desc "Download undownloaded github repositories"
  task new_github_repos: :environment do
    exit if ENV["READ_ONLY"].present?
    Project.undownloaded_repos.order("created_at DESC").find_each(&:update_repository_async)
  end

  desc "Download small registries all packages"
  task small_registries: %i[emacs hackage sublime inqlude shards]

  desc "Download Alcatraz packages asynchronously"
  task alcatraz: :environment do
    PackageManager::Alcatraz.import_async
  end

  desc "Download recent Atom packages asynchronously"
  task atom: :environment do
    PackageManager::Atom.import_recent_async
  end

  desc "Download all Atom packages asynchronously"
  task atom_all: :environment do
    PackageManager::Atom.import_async
  end

  desc "Download new Bower packages asynchronously"
  task bower: :environment do
    PackageManager::Bower.import_new_async
  end

  desc "Download all Bower packages"
  task bower_all: :environment do
    PackageManager::Bower.import
  end

  desc "Download recent Cargo packages asynchronously"
  task cargo: :environment do
    PackageManager::Cargo.import_recent_async
  end

  desc "Download all Carthage packages asynchronously"
  task carthage: :environment do
    PackageManager::Carthage.import_async
  end

  desc "Download recent Clojars packages"
  task clojars: :environment do
    PackageManager::Clojars.import_recent
  end

  desc "Download all Puppet packages asynchronously"
  task puppet_all: :environment do
    PackageManager::Puppet.import_async
  end

  desc "Download recent CPAN packages asynchronously"
  task cpan: :environment do
    PackageManager::CPAN.import_recent_async
  end

  desc "Download all CPAN packages asynchronously"
  task cpan_all: :environment do
    PackageManager::CPAN.import_async
  end

  desc "Download recent CocoaPods packages asynchronously"
  task cocoapods: :environment do
    PackageManager::CocoaPods.import_recent_async
  end

  desc "Download all CocoaPods packages asynchronously"
  task cocoapods_all: :environment do
    PackageManager::CocoaPods.import_async
  end

  desc "Download all Conda packages asynchronously"
  task conda_all: :environment do
    PackageManager::Conda.import_async
  end

  desc "Download recent Conda packages asynchronously"
  task conda: :environment do
    PackageManager::Conda.import_recent_async
  end

  desc "Download recent CRAN packages asynchronously"
  task cran: :environment do
    PackageManager::CRAN.import_recent_async
  end

  desc "Download all CRAN packages asynchronously"
  task cran_all: :environment do
    PackageManager::CRAN.import_async
  end

  desc "Download all Dub packages asynchronously"
  task dub: :environment do
    PackageManager::Dub.import_async
  end

  desc "Download recent Elm packages asynchronously"
  task elm: :environment do
    PackageManager::Elm.import_recent_async
  end

  desc "Download all Elm packages asynchronously"
  task elm_all: :environment do
    PackageManager::Elm.import_async
  end

  desc "Download all emacs packages asynchronously"
  task emacs: :environment do
    PackageManager::Emacs.import_async
  end

  desc "Download recent Hackage packages asynchronously"
  task hackage: :environment do
    PackageManager::Hackage.import_recent_async
  end

  desc "Download all Hackage packages asynchronously"
  task hackage_all: :environment do
    PackageManager::Hackage.import_async
  end

  desc "Download recent Haxelib packages asynchronously"
  task haxelib: :environment do
    PackageManager::Haxelib.import_recent_async
  end

  desc "Download all Haxelib packages asynchronously"
  task haxelib_all: :environment do
    PackageManager::Haxelib.import_async
  end

  desc "Download recent Hex packages asynchronously"
  task hex: :environment do
    PackageManager::Hex.import_recent_async
  end

  desc "Download all Hex packages"
  task hex_all: :environment do
    PackageManager::Hex.import
  end

  desc "Download recent Homebrew packages asynchronously"
  task homebrew: :environment do
    PackageManager::Homebrew.import_recent_async
  end

  desc "Download all Homebrew packages asynchronously"
  task homebrew_all: :environment do
    PackageManager::Homebrew.import_async
  end

  desc "Download all Inqlude packages"
  task inqlude: :environment do
    PackageManager::Inqlude.import
  end

  desc "Download all Julia packages asynchronously"
  task julia: :environment do
    PackageManager::Julia.import_async
  end

  desc "Download recent Maven packages asynchronously"
  task maven: :environment do
    PackageManager::Maven::PROVIDER_MAP.values.each do |sub_class|
      sub_class.import_recent_async
    rescue StandardError => e
      puts e
      next
    end
  end

  desc "Download all Maven packages asynchronously"
  task maven_all: :environment do
    PackageManager::Maven::PROVIDER_MAP.values.each do |sub_class|
      sub_class.import_async
    rescue StandardError => e
      puts e
      next
    end
  end

  desc "Download all Meteor packages asynchronously"
  task meteor: :environment do
    PackageManager::Meteor.import_async
  end

  desc "Download all Nimble packages asynchronously"
  task nimble: :environment do
    PackageManager::Nimble.import_async
  end

  desc "Download recent NuGet packages asynchronously"
  task nuget: :environment do
    PackageManager::NuGet.load_names(3)
    PackageManager::NuGet.import_recent_async
  end

  desc "Download all NuGet packages asynchronously"
  task nuget_all: :environment do
    PackageManager::NuGet.load_names
    PackageManager::NuGet.import_async
  end

  desc "Download recent NPM packages asynchronously"
  task npm: :environment do
    PackageManager::NPM.import_recent_async
  end

  desc "Download all NPM packages"
  task npm_all: :environment do
    PackageManager::NPM.import
  end

  desc "Download recent Packagist packages asynchronously"
  task packagist: :environment do
    PackageManager::Packagist.import_recent_async
  end

  desc "Download all Packagist packages asynchronously"
  task packagist_all: :environment do
    PackageManager::Packagist.import_async
  end

  desc "Download packages asynchronously"
  task platformio: :environment do
    PackageManager::PlatformIO.import_async
  end

  desc "Download new PureScript packages asynchronously"
  task purescript: :environment do
    PackageManager::PureScript.import_new_async
  end

  desc "Download all PureScript packages asynchronously"
  task purescript_all: :environment do
    PackageManager::PureScript.import_async
  end

  desc "Download recent Pub packages asynchronously"
  task pub: :environment do
    PackageManager::Pub.import_recent_async
  end

  desc "Download recent Pypi packages asynchronously"
  task pypi: :environment do
    PackageManager::Pypi.import_recent_async
  end

  desc "Download all Pypi packages asynchronously"
  task pypi_all: :environment do
    PackageManager::Pypi.import_async
  end

  desc "Download recent Racket packages asynchronously"
  task racket: :environment do
    PackageManager::Racket.import_async
  end

  desc "Download recent Rubygems packages asynchronously"
  task rubygems: :environment do
    PackageManager::Rubygems.import_recent_async
  end

  desc "Download all Rubygems packages asynchronously"
  task rubygems_all: :environment do
    PackageManager::Rubygems.import_async
  end

  desc "Download all Shards packages asynchronously"
  task shards: :environment do
    PackageManager::Shards.import_async
  end

  desc "Download all SwiftPM packages"
  task swift: :environment do
    PackageManager::SwiftPM.import
  end

  desc "Download all Sublime packages asynchronously"
  task sublime: :environment do
    PackageManager::Sublime.import_async
  end

  desc "Download recent Wordpress packages asynchronously"
  task wordpress: :environment do
    PackageManager::Wordpress.import_recent_async
  end

  desc "Download all Wordpress packages asynchronously"
  task wordpress_all: :environment do
    PackageManager::Wordpress.import_async
  end

  desc "Download new Go packages asynchronously"
  task go: :environment do
    PackageManager::Go.import_recent_async
  end

  desc "Download all Go packages asynchronously"
  task go_all: :environment do
    PackageManager::Go.import_async
  end
end
