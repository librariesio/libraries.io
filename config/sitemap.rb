# Set the host name for URL creation
SitemapGenerator::Sitemap.default_host = "https://libraries.io"
# pick a place safe to write the files
SitemapGenerator::Sitemap.public_path = 'tmp/'
# store on S3 using Fog
SitemapGenerator::Sitemap.adapter = SitemapGenerator::S3Adapter.new
# inform the map cross-linking where to find the other maps
SitemapGenerator::Sitemap.sitemaps_host = "https://#{ENV['FOG_DIRECTORY']}.s3.amazonaws.com/"
# pick a namespace within your bucket to organize your maps
SitemapGenerator::Sitemap.sitemaps_path = 'sitemaps/'

SitemapGenerator::Sitemap.create do
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

  add github_path
  add issues_path
  add github_organisations_path
  add github_search_path
  add trending_path
  add new_repos_path
  add github_timeline_path

  add platforms_path, :changefreq => 'daily'
  add licenses_path, :changefreq => 'daily'
  add languages_path, :changefreq => 'daily'
  add keywords_path, :changefreq => 'daily'

  puts "Generating Projects"
  Project.not_removed.find_each do |project|
    add project_path(project.to_param), :lastmod => project.updated_at
    add project_sourcerank_path(project.to_param), :lastmod => project.updated_at
    add project_dependents_path(project.to_param), :lastmod => project.updated_at, :priority => 0.4
    add project_dependent_repos_path(project.to_param), :lastmod => project.updated_at, :priority => 0.4
    add project_versions_path(project.to_param), :lastmod => project.updated_at, :priority => 0.4

    if project.versions_count.zero? && project.github_repository_id.present?
      if project.github_repository.present?
        add project_tags_path(project.to_param), :lastmod => project.updated_at, :priority => 0.4

        project.github_tags.published.find_each do |tag|
          add version_path(project.to_param.merge(number: tag.name)), :lastmod => project.updated_at
        end
      end
    end
  end

  Version.includes(:project).find_each do |version|
    if version.project && !version.project.is_removed?
      add version_path(version.to_param), :lastmod => version.project.updated_at
    end
  end

  GithubRepository.open_source.source.not_removed.find_each do |repo|
    add github_repository_path(repo.owner_name, repo.project_name), :lastmod => repo.updated_at
    add github_repository_contributors_path(repo.owner_name, repo.project_name), :lastmod => repo.updated_at
    add github_repository_forks_path(repo.owner_name, repo.project_name), :lastmod => repo.updated_at
  end

  puts "Generating Users"
  GithubUser.visible.find_each do |user|
    add user_path(user), :lastmod => user.updated_at
    add user_contributions_path(user), :lastmod => user.updated_at
    add user_repositories_path(user), :lastmod => user.updated_at
    add user_projects_path(user), :lastmod => user.updated_at
  end

  puts "Generating Orgs"
  GithubOrganisation.visible.find_each do |org|
    add user_path(org), :lastmod => org.updated_at
    add user_repositories_path(org), :lastmod => org.updated_at
    add user_projects_path(org), :lastmod => org.updated_at
  end

  Download.platforms.each do |platform|
    name = platform.to_s.demodulize
    add platform_path(name.downcase), :lastmod => Project.platform(name).order('updated_at DESC').first.try(:updated_at)
  end

  Project.popular_licenses(:facet_limit => 200).each do |license|
    name = license.term
    add license_path(name), :lastmod => Project.license(name).order('updated_at DESC').first.try(:updated_at)
  end

  Project.popular_languages(:facet_limit => 200).each do |language|
    name = language.term
    add language_path(name), :lastmod => Project.language(name).order('updated_at DESC').first.try(:updated_at)
  end

  Project.popular_keywords(:facet_limit => 1000).each do |keyword|
    name = keyword.term
    add keyword_path(name), :lastmod => Project.keyword(name).order('updated_at DESC').first.try(:updated_at)
  end
end
