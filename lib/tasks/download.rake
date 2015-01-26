namespace :download do
  task alcatraz: :environment do
    Repositories::Alcatraz.import
    Download.github_repos('Alcatraz')
    Download.download_contributors('Alcatraz')
  end

  task bower: :environment do
    Repositories::Bower.import
    Download.github_repos('Bower')
    Download.download_contributors('Bower')
  end

  task cargo: :environment do
    Repositories::Cargo.import
    Download.github_repos('Cargo')
    Download.download_contributors('Cargo')
  end

  task dub: :environment do
    Repositories::Dub.import
    Download.github_repos('Dub')
    Download.download_contributors('Dub')
  end

  task emacs: :environment do
    Repositories::Emacs.import
    Download.github_repos('Emacs')
    Download.download_contributors('Emacs')
  end

  task hackage: :environment do
    Repositories::Hackage.import
    Download.github_repos('Hackage')
    Download.download_contributors('Hackage')
  end

  task hex: :environment do
    Repositories::Hex.import
    Download.github_repos('Hex')
    Download.download_contributors('Hex')
  end

  task jam: :environment do
    Repositories::Jam.import
    Download.github_repos('Jam')
    Download.download_contributors('Jam')
  end

  task npm: :environment do
    Repositories::NPM.import
    Download.github_repos('NPM')
    Download.download_contributors('NPM')
  end

  task packagist: :environment do
    Repositories::Packagist.import
    Download.github_repos('Packagist')
    Download.download_contributors('Packagist')
  end

  task pub: :environment do
    Repositories::Pub.import
    Download.github_repos('Pub')
    Download.download_contributors('Pub')
  end

  task pypi: :environment do
    Repositories::Pypi.import
    Download.github_repos('Pypi')
    Download.download_contributors('Pypi')
  end

  task rubygems: :environment do
    Repositories::Rubygems.import
    Download.github_repos('Rubygems')
    Download.download_contributors('Rubygems')
  end

  task sublime: :environment do
    Repositories::Sublime.import
    Download.github_repos('Sublime')
    Download.download_contributors('Sublime')
  end
end
