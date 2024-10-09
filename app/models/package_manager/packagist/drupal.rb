# frozen_string_literal: true

class PackageManager::Packagist::Drupal < PackageManager::Packagist
  REPOSITORY_SOURCE_NAME = "Drupal"
  HIDDEN = true
  DRUPAL_MODULE_LICENSE = "GPL-2.0+" # Drupal plugins all use the same license

  def self.package_link(db_project, version = nil)
    if version
      "https://www.drupal.org/project/#{strip_drupal_namespace(db_project.name)}/releases/#{version}"
    else
      "https://www.drupal.org/project/#{strip_drupal_namespace(db_project.name)}"
    end
  end

  def self.project(name)
    get_html("https://www.drupal.org/project/#{strip_drupal_namespace(name)}")
  end

  def self.mapping(raw_project)
    homepage = raw_project.css("link[rel=canonical]").attr("href").value

    MappingBuilder.build_hash(
      name: "drupal/#{homepage.split('/project/', 2)[1]}",
      description: raw_project.css("meta[name=description]").first&.attr("content"),
      homepage: homepage,
      licenses: DRUPAL_MODULE_LICENSE,
      repository_url: raw_project
        .css("#block-drupalorg-project-development .links a")
        .find { |l| l.text =~ /code repository|source code/i }
        &.attr("href")
    )
  end

  def self.versions(_raw_project, name)
    name = strip_drupal_namespace(name)
    versions = []
    page = 0
    doc = get_html("https://www.drupal.org/project/#{name}/releases?page=#{page}")

    while !doc.css(".view-project-release-by-project .node-project-release").empty? && page < 50 # reasonable cap of 50
      versions += doc.css(".view-project-release-by-project .node-project-release")
        .map do |node|
          number = node.css("h2 a").text.split.last # e.g. "google_analytics 4.x-dev" => 4.x-dev
          release_doc = get_html("https://www.drupal.org/project/#{name}/releases/#{number}")
          published_at = release_doc
            .css(".release-info") # e.g. "Created by: user123\n\nCreated on: 1 Jun 2015 at 16:37 UTC\n\nLast updated: 25 May 2022 at 07:11 UTC"
            .first
            &.text
            &.scan(/Created on: (.*)/) # e.g. [["1 Jun 2015 at 16:37 UTC"]]
            &.first
            &.first
            &.strip # e.g. "12 May 2021 at 15:19 UTC"
          published_at = Time.parse(published_at) if published_at
          VersionBuilder.build_hash(
            number: number,
            published_at: published_at,
            original_license: DRUPAL_MODULE_LICENSE
          )
        end
      page += 1
      doc = get_html("https://www.drupal.org/project/#{name}/releases?page=#{page}")
    end

    versions
  end

  # TODO: is there a way to get these from Drupal?
  def self.dependencies(_name, _version, _mapped_project)
    []
  end

  private_class_method def self.strip_drupal_namespace(name)
    name.gsub(/^drupal\//, "")
  end
end
