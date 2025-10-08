# frozen_string_literal: true

require "parallel"

SitemapGenerator::Sitemap.default_host = "https://libraries.io"
SitemapGenerator::Sitemap.public_path = "tmp/"
SitemapGenerator::Sitemap.sitemaps_path = "sitemaps/"

SitemapGenerator::Sitemap.create(create_index: true) do
  projects = lambda {
    group = sitemap.group(filename: :projects, sitemaps_path: "sitemaps/projects") do
      Project.not_removed.where("rank > 0").find_each do |project|
        add project_path(project.to_param), lastmod: project.updated_at
      end
    end
    group.sitemap.write unless group.sitemap.written?
  }

  misc = lambda {
    group = sitemap.group(filename: :misc, sitemaps_path: "sitemaps/misc") do
      add root_path, priority: 1, changefreq: "daily"
    end
    group.sitemap.write unless group.sitemap.written?
  }

  Parallel.each([projects, misc], &:call)
end

SitemapGenerator::Sitemap.create(create_index: true) do
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
