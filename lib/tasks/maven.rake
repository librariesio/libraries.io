# frozen_string_literal: true

namespace :maven do
  task populate_google_maven: :environment do
    PackageManager::Maven::Google.update_all_versions
  end
end
