namespace :download do
  task all: :environment do
    Download.import
  end

  task hex: :environment do
    Repositories::Hex.import
  end

  task dub: :environment do
    Repositories::Dub.import
  end

  task emacs: :environment do
    Repositories::Emacs.import
  end

  task jam: :environment do
    Repositories::Jam.import
  end
end
