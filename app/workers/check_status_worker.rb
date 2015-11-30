class CheckStatusWorker
  include Sidekiq::Worker
  sidekiq_options queue: :low, unique: true

  def perform(project_id, platform, project_name)
    case platform.downcase
    when 'npm'
      response = Typhoeus.get("https://www.npmjs.com/package/#{project_name}")
    when 'rubygems'
      response = Typhoeus.get("https://rubygems.org/gems/#{project_name}")
    when 'packagist'
      response = Typhoeus.get("https://packagist.org/packages/#{project_name}")
    when 'nuget'
      response = Typhoeus.get("https://www.nuget.org/packages/#{project_name}")
    when 'wordpress'
      response = Typhoeus.get("https://wordpress.org/plugins/#{project_name}")
    when 'cpan'
      response = Typhoeus.get("https://metacpan.org/release/#{project_name}")
    when 'clojars'
      response = Typhoeus.get("https://clojars.org/#{project_name}")
    when 'cocoapods'
      response = Typhoeus.get("http://cocoapods.org/pods/#{project_name}")
    when 'hackage'
      response = Typhoeus.get("http://hackage.haskell.org/package/#{project_name}")
    when 'cran'
      response = Typhoeus.get("http://cran.r-project.org/web/packages/#{project_name}/index.html")
    when 'atom'
      response = Typhoeus.get("https://atom.io/packages/#{project_name}")
    when 'cargo'
      response = Typhoeus.get("https://crates.io/crates/#{project_name}")
    when 'sublime'
      response = Typhoeus.get("https://packagecontrol.io/packages/#{project_name}")
    when 'pub'
      response = Typhoeus.get("https://pub.dartlang.org/packages/#{project_name}")
    when 'hex'
      response = Typhoeus.get("https://hex.pm/packages/#{project_name}")
    when 'elm'
      response = Typhoeus.get("http://package.elm-lang.org/packages/#{project_name}/latest")
    when 'dub'
      response = Typhoeus.get("http://code.dlang.org/packages/#{project_name}")
    end

    if platform == 'packagist' && response.response_code == 302
      project = Project.find_by_id project_id
      project.update_attribute(:status, 'Removed') if project
    elsif platform != 'packagist' && response.response_code == 404
      project = Project.find_by_id project_id
      project.update_attribute(:status, 'Removed') if project
    end
  end
end
