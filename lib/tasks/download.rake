namespace :download do
  task all: :environment do
    Download.import
  end

  task alcatraz: :environment do
    Repositories::Alcatraz.import
  end

  task bower: :environment do
    Repositories::Bower.import
  end

  task dub: :environment do
    Repositories::Dub.import
  end

  task emacs: :environment do
    Repositories::Emacs.import
  end

  task hex: :environment do
    Repositories::Hex.import
  end

  task jam: :environment do
    Repositories::Jam.import
  end

  task npm: :environment do
    Repositories::NPM.import
  end

  task pub: :environment do
    Repositories::Pub.import
  end

  task rubygems: :environment do
    Repositories::Rubygems.import
  end

  task sublime: :environment do
    Repositories::Sublime.import
  end

  task pypi: :environment do
    Repositories::Pypi.import
  end
end
