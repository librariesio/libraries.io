class CheckStatusWorker
  include Sidekiq::Worker
  sidekiq_options queue: :low, unique: true

  def perform(project_id)
    project = Project.find_by_id project_id
    return unless project
    case project.platform.downcase
    when 'npm'
      response = Typhoeus.get("https://www.npmjs.com/package/#{project.name}")
      project.update_attribute(:status, 'Removed') if response.response_code == 404
    when 'rubygems'
      response = Typhoeus.get("https://rubygems.org/gems/#{project.name}")
      project.update_attribute(:status, 'Removed') if response.response_code == 404
    when 'packagist'
      response = Typhoeus.get("https://packagist.org/packages/#{project.name}")
      project.update_attribute(:status, 'Removed') if response.response_code == 302
    when 'nuget'
      response = Typhoeus.get("https://www.nuget.org/packages/#{name}")
      project.update_attribute(:status, 'Removed') if response.response_code == 404
    when 'wordpress'
      response = Typhoeus.get("https://wordpress.org/plugins/#{name}")
      project.update_attribute(:status, 'Removed') if response.response_code == 404
    when 'cpan'
      response = Typhoeus.get("https://metacpan.org/release/#{name}")
      project.update_attribute(:status, 'Removed') if response.response_code == 404
    when 'clojars'
      response = Typhoeus.get("https://clojars.org/#{name}")
      project.update_attribute(:status, 'Removed') if response.response_code == 404
    when 'cocoapods'
      response = Typhoeus.get("http://cocoapods.org/pods/#{name}")
      project.update_attribute(:status, 'Removed') if response.response_code == 404
    when 'hackage'
      response = Typhoeus.get("http://hackage.haskell.org/package/#{name}")
      project.update_attribute(:status, 'Removed') if response.response_code == 404
    when 'cran'
      response = Typhoeus.get("http://cran.r-project.org/web/packages/#{name}/index.html")
      project.update_attribute(:status, 'Removed') if response.response_code == 404
    when 'atom'
      response = Typhoeus.get("https://atom.io/packages/#{name}")
      project.update_attribute(:status, 'Removed') if response.response_code == 404
    when 'cargo'
      response = Typhoeus.get("https://crates.io/crates/#{name}/#{version}")
      project.update_attribute(:status, 'Removed') if response.response_code == 404
    when 'sublime'
      response = Typhoeus.get("https://packagecontrol.io/packages/#{name}")
      project.update_attribute(:status, 'Removed') if response.response_code == 404
    when 'pub'
      response = Typhoeus.get("https://pub.dartlang.org/packages/#{name}")
      project.update_attribute(:status, 'Removed') if response.response_code == 404
    when 'hex'
      response = Typhoeus.get("https://hex.pm/packages/#{name}/#{version}")
      project.update_attribute(:status, 'Removed') if response.response_code == 404
    when 'elm'
      response = Typhoeus.get("http://package.elm-lang.org/packages/#{name}/latest")
      project.update_attribute(:status, 'Removed') if response.response_code == 404
    when 'dub'
      response = Typhoeus.get("http://code.dlang.org/packages/#{name}")
      project.update_attribute(:status, 'Removed') if response.response_code == 404
    end
  end
end
