# Set the host name for URL creation
SitemapGenerator::Sitemap.default_host = "http://libraries.io"

SitemapGenerator::Sitemap.create do
  puts "Generating Projects"
  Project.find_each do |project|
    add project_path(project), :lastmod => project.updated_at
    project.versions.find_each do |version|
      add project_version_path(project, version), :lastmod => project.updated_at
    end
  end

  puts "Generating Users"
  GithubUser.find_each do |user|
    add user_path(user.downcase), :lastmod => user.updated_at
  end

  puts "Generating Platforms"
  add platforms_path, :priority => 0.7, :changefreq => 'daily'
  Download.platforms.each do |platform|
    name = platform.to_s.demodulize
    add platform_path(name.downcase), :lastmod => Project.platform(name).order('updated_at DESC').first.try(:updated_at)
  end

  puts "Generating Licenses"
  add licenses_path, :priority => 0.7, :changefreq => 'daily'
  Project.popular_licenses.limit(20).each do |license|
    name = license.licenses
    add license_path(name.downcase), :lastmod => Project.license(name).order('updated_at DESC').first.try(:updated_at)
  end
end
