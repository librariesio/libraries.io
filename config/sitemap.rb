require 'parallel'

SitemapGenerator::Sitemap.default_host = "https://libraries.io"
SitemapGenerator::Sitemap.public_path = 'tmp/'
SitemapGenerator::Sitemap.sitemaps_path = 'sitemaps/'
SitemapGenerator::Sitemap.search_engines[:yandex] = 'https://blogs.yandex.ru/pings/?status=success&url=%s'

SitemapGenerator::Sitemap.create(:create_index => true) do
  projects = lambda {
    group = sitemap.group(:filename => :projects, :sitemaps_path => 'sitemaps/projects') do
      Project.not_removed.where("rank > 0").find_each do |project|
        add project_path(project.to_param), :lastmod => project.updated_at
      end
    end
    group.sitemap.write unless group.sitemap.written?
  }

  orgs = lambda {
    group = sitemap.group(:filename => :orgs, :sitemaps_path => 'sitemaps/orgs') do
      RepositoryOrganisation.visible.with_login.find_each do |user|
        add user_path(user.to_param), :lastmod => user.updated_at
      end
    end
    group.sitemap.write unless group.sitemap.written?
  }

  users = lambda {
    group = sitemap.group(:filename => :users, :sitemaps_path => 'sitemaps/users') do
      RepositoryUser.visible.with_login.find_each do |user|
        add user_path(user.to_param), :lastmod => user.updated_at
      end
    end
    group.sitemap.write unless group.sitemap.written?
  }

  repos = lambda {
    group = sitemap.group(:filename => :repos, :sitemaps_path => 'sitemaps/repos') do
      Repository.open_source.source.not_removed.where("rank > 0").find_each do |repo|
        add repository_path(repo.to_param), :lastmod => repo.updated_at
        add repository_contributors_path(repo.to_param), :lastmod => repo.updated_at
      end
    end
    group.sitemap.write unless group.sitemap.written?
  }


  misc = lambda {
    group = sitemap.group(:filename => :misc, :sitemaps_path => 'sitemaps/misc') do
      add root_path, :priority => 1, :changefreq => 'daily'

      add search_path
      add about_path

      add bus_factor_path
      add unlicensed_path
      add unmaintained_path
      add deprecated_path
      add removed_path
      add help_wanted_path
      add first_pull_request_path

      add hosts_path
      add issues_path
      add repository_organisations_path
      add github_search_path
      add trending_path
      add trending_projects_path
      add new_repos_path
      add github_timeline_path
      add github_languages_path

      add explore_path

      add platforms_path, :changefreq => 'daily'
      add licenses_path, :changefreq => 'daily'
      add languages_path, :changefreq => 'daily'
      add keywords_path, :changefreq => 'daily'

      PackageManager::Base.platforms.each do |platform|
        name = platform.formatted_name
        add platform_path(name.downcase), :lastmod => Project.platform(name).order('updated_at DESC').first.try(:updated_at)
      end

      Project.popular_licenses(:facet_limit => 300).each do |license|
        name = license['key']
        add license_path(name), :lastmod => Project.license(name).order('updated_at DESC').first.try(:updated_at)
      end

      Project.popular_languages(:facet_limit => 200).each do |language|
        name = language['key']
        add language_path(name), :lastmod => Project.language(name).order('updated_at DESC').first.try(:updated_at)
      end

      Project.popular_keywords(:facet_limit => 1000).each do |keyword|
        name = keyword['key']
        add keyword_path(name), :lastmod => Project.keyword(name).order('updated_at DESC').first.try(:updated_at)
      end
    end
    group.sitemap.write unless group.sitemap.written?
  }

  Parallel.each([projects, orgs, users, repos, misc]) do |group|
    group.call
  end
end

SitemapGenerator::Sitemap.create(:create_index => true) do
  Dir.chdir(sitemap.public_path.to_s)
  xml_files      = File.join("**", "sitemaps", "**", "*.xml.gz")
  xml_file_paths = Dir.glob(xml_files)

  xml_file_paths.each do |file|
    next if file.match(/sitemaps\/sitemap/)
    add_to_index file
  end
end

# upload to gcs... the gem can upload to gcs but only using fog which can't use
# instance credentials which ends up being complicated so just punt and call
# gsutil directly
if Rails.env.production?
  Dir.chdir(sitemap.public_path.to_s)
  `gsutil rsync -dr sitemaps/ gs://libraries-sitemap/sitemaps/`
end

