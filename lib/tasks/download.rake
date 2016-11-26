namespace :download do
  task new_github_repos: :environment do
    Project.undownloaded_repos.order('created_at DESC').find_each(&:update_github_repo_async)
  end

  task small_registries: [:emacs, :hackage, :sublime, :inqlude, :shards]

  task alcatraz: :environment do
    Repositories::Alcatraz.import_async
  end

  task atom: :environment do
    Repositories::Atom.import_recent_async
  end

  task atom_all: :environment do
    Repositories::Atom.import_async
  end

  task bower: :environment do
    Repositories::Bower.import_new_async
  end

  task cargo: :environment do
    Repositories::Cargo.import_recent_async
  end

  task carthage: :environment do
    Repositories::Carthage.import_async
  end

  task clojars: :environment do
    Repositories::Clojars.import_recent
  end

  task cpan: :environment do
    Repositories::CPAN.import_recent_async
  end

  task cpan_all: :environment do
    Repositories::CPAN.import_async
  end

  task cocoapods: :environment do
    Repositories::CocoaPods.import_recent_async
  end

  task cran: :environment do
    Repositories::CRAN.import_recent_async
  end

  task cran_all: :environment do
    Repositories::CRAN.import_async
  end

  task dub: :environment do
    Repositories::Dub.import_async
  end

  task elm: :environment do
    Repositories::Elm.import_recent_async
  end

  task elm_all: :environment do
    Repositories::Elm.import_async
  end

  task emacs: :environment do
    Repositories::Emacs.import_async
  end

  task hackage: :environment do
    Repositories::Hackage.import_recent_async
  end

  task hackage_all: :environment do
    Repositories::Hackage.import_async
  end

  task haxelib: :environment do
    Repositories::Haxelib.import_recent_async
  end

  task haxelib_all: :environment do
    Repositories::Haxelib.import
  end

  task hex: :environment do
    Repositories::Hex.import_recent_async
  end

  task hex_all: :environment do
    Repositories::Hex.import
  end

  task homebrew: :environment do
    Repositories::Homebrew.import_recent_async
  end

  task homebrew_all: :environment do
    Repositories::Homebrew.import_async
  end

  task inqlude: :environment do
    Repositories::Inqlude.import
  end

  task julia: :environment do
    Repositories::Julia.import_async
  end

  task maven: :environment do
    Repositories::Maven.load_names(50)
    Repositories::Maven.import_recent_async
  end

  task maven_all: :environment do
    Repositories::Maven.load_names
    Repositories::Maven.import_async
  end

  task meteor: :environment do
    Repositories::Meteor.import_async
  end

  task nimble: :environment do
    Repositories::Nimble.import_async
  end

  task nuget: :environment do
    Repositories::NuGet.load_names(3)
    Repositories::NuGet.import_recent_async
  end

  task nuget_all: :environment do
    Repositories::NuGet.load_names
    Repositories::NuGet.import
  end

  task npm: :environment do
    Repositories::NPM.import_recent_async
  end

  task npm_all: :environment do
    Repositories::NPM.import
  end

  task packagist: :environment do
    Repositories::Packagist.import_recent_async
  end

  task packagist_all: :environment do
    Repositories::Packagist.import_async
  end

  task platformio: :environment do
    Repositories::PlatformIO.import
  end

  task pub: :environment do
    Repositories::Pub.import_recent_async
  end

  task pypi: :environment do
    Repositories::Pypi.import_recent_async
  end

  task pypi_all: :environment do
    Repositories::Pypi.import_async
  end

  task rubygems: :environment do
    Repositories::Rubygems.import_recent_async
  end

  task rubygems_all: :environment do
    Repositories::Rubygems.import_async
  end

  task shards: :environment do
    Repositories::Shards.import_async
  end

  task swift: :environment do
    Repositories::SwiftPM.import
  end

  task sublime: :environment do
    Repositories::Sublime.import_async
  end

  task wordpress: :environment do
    Repositories::Wordpress.import_recent_async
  end

  task wordpress_all: :environment do
    Repositories::Wordpress.import_async
  end

  task go: :environment do
    Repositories::Go.import_new_async
  end

  task go_all: :environment do
    Repositories::Go.import_async
  end
end
