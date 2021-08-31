# frozen_string_literal: true

class PackageManager::Packagist::Drupal < PackageManager::Packagist
  REPOSITORY_SOURCE_NAME = "Drupal"
  HIDDEN = true
  DRUPAL_MODULE_LICENSE = "GPL-2.0-or-later" # Drupal plugins all use the same license

  def self.package_link(project, version = nil)
    if version
      "https://www.drupal.org/project/#{strip_drupal_namespace(project.name)}/releases/#{version}"
    else
      "https://www.drupal.org/project/#{strip_drupal_namespace(project.name)}"
    end
  end

  def self.project(name)
    get_html("https://www.drupal.org/project/#{strip_drupal_namespace(name)}")
  end

  def self.mapping(raw_project)
    most_recent_versions = raw_project.css('.view-drupalorg-project-downloads .release')
    return nil unless most_recent_versions.any?

    homepage = raw_project.css("link[rel=canonical]").attr('href').value

    {
      name: "drupal/#{homepage.split("/project/", 2)[1]}",
      description: raw_project.css("meta[name=description]").first.attr('content'),
      homepage: homepage,
      licenses: DRUPAL_MODULE_LICENSE,
      repository_url: raw_project.css('#block-drupalorg-project-development .links a').find { |l| l.text =~ /code repository/ }.attr('href'),
    }
  end

  def self.versions(_raw_project, name)
    name = strip_drupal_namespace(name)
    versions = []
    page = 0
    doc = get_html("https://www.drupal.org/project/#{name}/releases?page=#{page}")

    while doc.css('.view-project-release-by-project .node-project-release').size > 0 && page < 50 # reasonable cap of 50
      versions += doc.css('.view-project-release-by-project .node-project-release')
        .map do |node|
          {
            number: node.css("h2 a").text.split(' ').last, # e.g. "google_analytics 4.x-dev" => 4.x-dev
            published_at: Time.at(node.css('.submitted time').first.attr('datetime').to_i),
            original_license: DRUPAL_MODULE_LICENSE

          }
        end
      page += 1
      doc = get_html("https://www.drupal.org/project/#{name}/releases?page=#{page}")
    end

    versions
  end

  # TODO is there a way to get these from Drupal?
  def self.dependencies(_name, version, mapped_project)
    []
  end

  private_class_method def self.strip_drupal_namespace(name)
    name.gsub(/^drupal\//, '')
  end
end
