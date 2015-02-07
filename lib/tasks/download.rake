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
    Download.update_repos('Alcatraz')
  end

  task bower: :environment do
    Repositories::Bower.import
  end

  task cargo: :environment do
    Repositories::Cargo.import
    Download.update_repos('Cargo')
  end

  task dub: :environment do
    Repositories::Dub.import
    Download.update_repos('Dub')
  end

  task emacs: :environment do
    Repositories::Emacs.import
    Download.update_repos('Emacs')
  end

  task hackage: :environment do
    Repositories::Hackage.import
    Download.update_repos('Hackage')
  end

  task hex: :environment do
    Repositories::Hex.import
    Download.update_repos('Hex')
  end

  task jam: :environment do
    Repositories::Jam.import
    Download.update_repos('Jam')
  end

  task maven: :environment do
    Repositories::Maven.load_names(50)
    Repositories::Maven.import
  end

  task nimble: :environment do
    Repositories::Nimble.import
    Download.update_repos('Nimble')
  end

  task npm: :environment do
    Repositories::NPM.import
  end

  task packagist: :environment do
    Repositories::Packagist.import
  end

  task pub: :environment do
    Repositories::Pub.import
    Download.update_repos('Pub')
  end

  task pypi: :environment do
    Repositories::Pypi.import
  end

  task rubygems: :environment do
    Repositories::Rubygems.import
  end

  task sublime: :environment do
    Repositories::Sublime.import
    Download.update_repos('Sublime')
  end
end
