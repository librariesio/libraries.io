namespace :one_off do
  # put your one off tasks here and delete them once they've been ran

  task generate_api_keys: :environment do
    User.find_each(&:create_api_key)
  end
end
