namespace :download do
  task new_github_repos: :environment do
    Project.undownloaded_repos.order('created_at DESC').find_each(&:update_github_repo_async)
  end

  task small_registries: [:emacs, :hackage, :sublime, :inqlude, :shards]

  task alcatraz: :environment do
    PackageManager::Alcatraz.import_async
  end

  task atom: :environment do
    PackageManager::Atom.import_recent_async
  end

  task atom_all: :environment do
    PackageManager::Atom.import_async
  end

  task bower: :environment do
    PackageManager::Bower.import_new_async
  end

  task bower_all: :environment do
    if Date.today.wday.zero?
      PackageManager::Bower.import
    end
  end

  task cargo: :environment do
    PackageManager::Cargo.import_recent_async
  end

  task carthage: :environment do
    PackageManager::Carthage.import_async
  end

  task clojars: :environment do
    PackageManager::Clojars.import_recent
  end

  task cpan: :environment do
    PackageManager::CPAN.import_recent_async
  end

  task cpan_all: :environment do
    PackageManager::CPAN.import_async
  end

  task cocoapods: :environment do
    PackageManager::CocoaPods.import_recent_async
  end

  task cran: :environment do
    PackageManager::CRAN.import_recent_async
  end

  task cran_all: :environment do
    PackageManager::CRAN.import_async
  end

  task dub: :environment do
    PackageManager::Dub.import_async
  end

  task elm: :environment do
    PackageManager::Elm.import_recent_async
  end

  task elm_all: :environment do
    PackageManager::Elm.import_async
  end

  task emacs: :environment do
    PackageManager::Emacs.import_async
  end

  task hackage: :environment do
    PackageManager::Hackage.import_recent_async
  end

  task hackage_all: :environment do
    PackageManager::Hackage.import_async
  end

  task haxelib: :environment do
    PackageManager::Haxelib.import_recent_async
  end

  task haxelib_all: :environment do
    PackageManager::Haxelib.import
  end

  task hex: :environment do
    PackageManager::Hex.import_recent_async
  end

  task hex_all: :environment do
    PackageManager::Hex.import
  end

  task homebrew: :environment do
    PackageManager::Homebrew.import_recent_async
  end

  task homebrew_all: :environment do
    PackageManager::Homebrew.import_async
  end

  task inqlude: :environment do
    PackageManager::Inqlude.import
  end

  task julia: :environment do
    PackageManager::Julia.import_async
  end

  task maven: :environment do
    PackageManager::Maven.load_names(50)
    PackageManager::Maven.import_recent_async
  end

  task maven_all: :environment do
    PackageManager::Maven.load_names
    PackageManager::Maven.import_async
  end

  task meteor: :environment do
    PackageManager::Meteor.import_async
  end

  task nimble: :environment do
    PackageManager::Nimble.import_async
  end

  task nuget: :environment do
    PackageManager::NuGet.load_names(3)
    PackageManager::NuGet.import_recent_async
  end

  task nuget_all: :environment do
    PackageManager::NuGet.load_names
    PackageManager::NuGet.import
  end

  task npm: :environment do
    PackageManager::NPM.import_recent_async
  end

  task npm_all: :environment do
    PackageManager::NPM.import
  end

  task packagist: :environment do
    PackageManager::Packagist.import_recent_async
  end

  task packagist_all: :environment do
    PackageManager::Packagist.import_async
  end

  task platformio: :environment do
    PackageManager::PlatformIO.import
  end

  task pub: :environment do
    PackageManager::Pub.import_recent_async
  end

  task pypi: :environment do
    PackageManager::Pypi.import_recent_async
  end

  task pypi_all: :environment do
    PackageManager::Pypi.import_async
  end

  task rubygems: :environment do
    PackageManager::Rubygems.import_recent_async
  end

  task rubygems_all: :environment do
    PackageManager::Rubygems.import_async
  end

  task shards: :environment do
    PackageManager::Shards.import_async
  end

  task swift: :environment do
    PackageManager::SwiftPM.import
  end

  task sublime: :environment do
    PackageManager::Sublime.import_async
  end

  task wordpress: :environment do
    PackageManager::Wordpress.import_recent_async
  end

  task wordpress_all: :environment do
    PackageManager::Wordpress.import_async
  end

  task go: :environment do
    PackageManager::Go.import_new_async
  end

  task go_all: :environment do
    PackageManager::Go.import_async
  end
end
