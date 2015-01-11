namespace :download do
  task all: :environment do
    Download.import
  end

  task hex: :environment do
    Repositories::Hex.import
  end
end
