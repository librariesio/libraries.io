namespace :download do
  task new_github_repos: :environment do
    Download.new_github_repos
  end

  task update_github_repos: :environment do
    Download.update_github_repos
  end

  task github_contributors: :environment do
    Download.download_contributors
  end

  task small_registries: [:alcatraz, :cargo, :dub, :emacs, :hackage, :hex, :jam, :nimble, :sublime]

  task alcatraz: :environment do
    Repositories::Alcatraz.import
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
    Repositories::CPAN.import_recent
  end

  task cran: :environment do
    Repositories::CPAN.import_recent
  end

  task dub: :environment do
    Repositories::Dub.import
  end

  task emacs: :environment do
    Repositories::Emacs.import
  end

  task hackage: :environment do
    Repositories::Hackage.import_recent
  end

  task hex: :environment do
    Repositories::Hex.import
  end

  task jam: :environment do
    Repositories::Jam.import
  end

  task maven: :environment do
    Repositories::Maven.load_names(50)
    Repositories::Maven.import_recent
  end

  task meteor: :environment do
    Repositories::Meteor.import
  end

  task nimble: :environment do
    Repositories::Nimble.import
  end

  task nuget: :environment do
    Repositories::NuGet.load_names
    Repositories::NuGet.import
  end

  task npm: :environment do
    Repositories::NPM.import_recent
  end

  task npm_all: :environment do
    Repositories::NPM.import
  end

  task packagist: :environment do
    Repositories::Packagist.import_recent
  end

  task packagist_all: :environment do
    Repositories::Packagist.import
  end

  task pub: :environment do
    Repositories::Pub.import
  end

  task pypi: :environment do
    Repositories::Pypi.import_recent
  end

  task rubygems: :environment do
    Repositories::Rubygems.import_recent
  end

  task sublime: :environment do
    Repositories::Sublime.import
  end

  task wordpress: :environment do
    Repositories::Wordpress.import_recent
  end

  task go: :environment do
    Repositories::Go.import_new
  end
end
