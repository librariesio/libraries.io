namespace :download do
  task stats: :environment do
    Download.stats
  end

  task new_github_repos: :environment do
    Download.new_github_repos
  end

  task github_contributors: :environment do
    Download.download_contributors
  end

  task alcatraz: :environment do
    Repositories::Alcatraz.import
    Download.update_repos('Alcatraz')
  end

  task bower: :environment do
    Repositories::Bower.import
    Download.github_repos('Bower')
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
    Download.github_repos('Hackage')
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
    Repositories::Maven.load_names
    Repositories::Maven.import(false)
    # Download.update_repos('Maven')
  end

  task nimble: :environment do
    Repositories::Nimble.import
    Download.update_repos('Nimble')
  end

  task npm: :environment do
    Repositories::NPM.import
    # Download.github_repos('NPM')
  end

  task packagist: :environment do
    Repositories::Packagist.import
    # Download.github_repos('Packagist')
  end

  task pub: :environment do
    Repositories::Pub.import
    Download.github_repos('Pub')
  end

  task pypi: :environment do
    Repositories::Pypi.import
    Download.github_repos('Pypi')
  end

  task rubygems: :environment do
    Repositories::Rubygems.import
    # Download.github_repos('Rubygems')
  end

  task sublime: :environment do
    Repositories::Sublime.import
    Download.update_repos('Sublime')
  end
end
