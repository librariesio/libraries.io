class CheckStatusWorker
  include Sidekiq::Worker
  sidekiq_options queue: :low, unique: true

  def perform(project_id, platform, project_name, removed = false)
    case platform.downcase
    when 'npm'
      response = Typhoeus.head("https://www.npmjs.com/package/#{project_name}")
    when 'rubygems'
      response = Typhoeus.head("https://rubygems.org/gems/#{project_name}")
    when 'packagist'
      response = Typhoeus.head("https://packagist.org/packages/#{project_name}")
    when 'nuget'
      response = Typhoeus.head("https://www.nuget.org/packages/#{project_name}")
    when 'wordpress'
      response = Typhoeus.head("https://wordpress.org/plugins/#{project_name}")
    when 'cpan'
      response = Typhoeus.head("https://metacpan.org/release/#{project_name}")
    when 'clojars'
      response = Typhoeus.head("https://clojars.org/#{project_name}")
    when 'cocoapods'
      response = Typhoeus.head("http://cocoapods.org/pods/#{project_name}")
    when 'hackage'
      response = Typhoeus.head("http://hackage.haskell.org/package/#{project_name}")
    when 'cran'
      response = Typhoeus.head("http://cran.r-project.org/web/packages/#{project_name}/index.html")
    when 'atom'
      response = Typhoeus.head("https://atom.io/packages/#{project_name}")
    when 'cargo'
      response = Typhoeus.head("https://crates.io/crates/#{project_name}")
    when 'sublime'
      response = Typhoeus.head("https://packagecontrol.io/packages/#{project_name}")
    when 'pub'
      response = Typhoeus.head("https://pub.dartlang.org/packages/#{project_name}")
    when 'hex'
      response = Typhoeus.head("https://hex.pm/packages/#{project_name}")
    when 'elm'
      response = Typhoeus.head("http://package.elm-lang.org/packages/#{project_name}/latest")
    when 'dub'
      response = Typhoeus.head("http://code.dlang.org/packages/#{project_name}")
    end

    if platform == 'packagist' && response.response_code == 302
      project = Project.find_by_id project_id
      project.update_attribute(:status, 'Removed') if project
    elsif platform != 'packagist' && response.response_code == 404
      project = Project.find_by_id project_id
      project.update_attribute(:status, 'Removed') if project
    elsif removed
      project = Project.find_by_id project_id
      project.update_attribute(:status, nil) if project
    end
  end
end
