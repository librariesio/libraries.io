namespace :download do
  task new_github_repos: :environment do
    Download.new_github_repos
  end

  task small_registries: [:emacs, :hackage, :sublime]

  task alcatraz: :environment do
    Repositories::Alcatraz.import
  end

  task atom: :environment do
    Repositories::Atom.import_async
  end

  task atom_all: :environment do
    Repositories::Atom.import
  end

  task biicode: :environment do
    Repositories::Biicode.import
  end

  task bower: :environment do
    Repositories::Bower.import_new
  end

  task cargo: :environment do
    Repositories::Cargo.import
  end

  task clojars: :environment do
    Repositories::Clojars.import
  end

  task cpan: :environment do
    Repositories::CPAN.import_async
  end

  task cpan_all: :environment do
    Repositories::CPAN.import
  end

  task cocoapods: :environment do
    Repositories::CocoaPods.import
  end

  task cran: :environment do
    Repositories::CRAN.import_async
  end

  task cran_all: :environment do
    Repositories::CRAN.import
  end

  task dub: :environment do
    Repositories::Dub.import
  end

  task elm: :environment do
    Repositories::Elm.import
  end

  task emacs: :environment do
    Repositories::Emacs.import
  end

  task hackage: :environment do
    Repositories::Hackage.import_async
  end

  task hackage_all: :environment do
    Repositories::Hackage.import
  end

  task hex: :environment do
    Repositories::Hex.import_async
  end

  task hex_all: :environment do
    Repositories::Hex.import
  end

  task jam: :environment do
    Repositories::Jam.import
  end

  task julia: :environment do
    Repositories::Julia.import
  end

  task maven: :environment do
    Repositories::Maven.load_names(50)
    Repositories::Maven.import_async
  end

  task maven_all: :environment do
    Repositories::Maven.load_names
    Repositories::Maven.import
  end

  task meteor: :environment do
    Repositories::Meteor.import
  end

  task nimble: :environment do
    Repositories::Nimble.import
  end

  task nuget: :environment do
    Repositories::NuGet.load_names(3)
    Repositories::NuGet.import_async
  end

  task nuget_all: :environment do
    Repositories::NuGet.load_names
    Repositories::NuGet.import
  end

  task npm: :environment do
    Repositories::NPM.import_async
  end

  task npm_all: :environment do
    Repositories::NPM.import
  end

  task packagist: :environment do
    Repositories::Packagist.import_async
  end

  task packagist_all: :environment do
    Repositories::Packagist.import
  end

  task platformio: :environment do
    Repositories::PlatformIO.import
  end

  task pub: :environment do
    Repositories::Pub.import
  end

  task pypi: :environment do
    Repositories::Pypi.import_async
  end

  task pypi_all: :environment do
    Repositories::Pypi.import
  end

  task rubygems: :environment do
    Repositories::Rubygems.import_async
  end

  task rubygems_all: :environment do
    Repositories::Rubygems.import
  end

  task sublime: :environment do
    Repositories::Sublime.import
  end

  task wordpress: :environment do
    Repositories::Wordpress.import_async
  end

  task wordpress_all: :environment do
    Repositories::Wordpress.import
  end

  task go: :environment do
    Repositories::Go.import_new
  end

  task go_all: :environment do
    Repositories::Go.import
  end
end
