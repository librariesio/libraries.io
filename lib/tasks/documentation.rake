namespace :documentation do
  desc 'Generate Package Manager Matrix'
  task package_manager_matrix: :environment do
    puts '| Name  | Website | Main Language | Versions | Dependencies | Biblothecary support |'
    puts '| ------------- | ------------- | ------------- | ------------- | ------------- | ------------- |'
    Dir[Rails.root.join('app', 'models', 'package_manager', '*.rb')].each do|file|
      require file unless file.match(/base.rb$/)
    end
    PackageManager::Base.platforms.each do |platform|
      puts "| #{platform.formatted_name} | #{platform.homepage} | #{platform.default_language} | #{platform::HAS_VERSIONS} | #{platform::HAS_DEPENDENCIES} | #{platform::BIBLIOTHECARY_SUPPORT} |"
    end
  end
end
