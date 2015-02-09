namespace :download do
  task stats: :environment do
    Download.stats
  end

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
    Repositories::Bower.import
  end

  task cargo: :environment do
    Repositories::Cargo.import
  end

  task dub: :environment do
    Repositories::Dub.import
  end

  task emacs: :environment do
    Repositories::Emacs.import
  end

  task hackage: :environment do
    Repositories::Hackage.import
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

  task nimble: :environment do
    Repositories::Nimble.import
  end

  task npm: :environment do
    Repositories::NPM.import_recent
  end

  task packagist: :environment do
    Repositories::Packagist.import_recent
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
end
