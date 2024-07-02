# frozen_string_literal: true

class PackageManager::Maven::MavenCentral < PackageManager::Maven::Common
  REPOSITORY_SOURCE_NAME = "Maven"
  HIDDEN = true

  def self.repository_base
    "https://repo1.maven.org/maven2"
  end

  def self.recent_names
    get("https://maven.libraries.io/mavenCentral/recent")
  end

  def self.missing_version_remover
    PackageManager::Base::MissingVersionRemover
  end

  # Attempt to scrape MavenCentral's index HTML to infer the latest version.
  def self.latest_version_scraped(name)
    versions = get_html(MavenUrl.from_name(name, repository_base, NAME_DELIMITER).base)
      .css("#contents a")                                  # scrape the list of file/folders
      .map(&:text)                                         # get each innerText
      .select { |text| text.end_with?("/") }               # only look at folders
      .map { |folder| folder.chomp("/") }                  # remove folder trailing slash
      .grep(/^\d+.\d/)                                     # only folders that look like versions

    # Maven versions range from 1 to many "." and may not be valid SemVer. Use the more forgiving Gem::Version to sort
    # but we also want to prefer things that _don't_ look like a date as that's an ancient maven practice
    dated_versions, nodate_versions = versions.partition { |v| v =~ /\d{8}.\d+/ }
    if nodate_versions.count > 0
      nodate_versions.max_by { |v| Gem::Version.new(v) }
    else
      dated_versions.max_by { |v| Gem::Version.new(v) }
    end
  rescue ArgumentError
    Bugsnag.notify("Couldn't find scraped HTML version for #{name}. Check the HTML and ensure scraping still works.")
    nil
  end

  # maven-metadata.xml for Maven Central does not appear to be guaranteed to contain all relevant versions for a package
  # So instead, if needed, we will retrieve the versions from the raw HTML index page
  def self.versions(raw_project, name)
    if raw_project && raw_project[:versions]
      raw_project[:versions]
    else
      retrieve_versions(versions_from_html(name), name)
    end
  end

  def self.versions_from_html(name)
    get_html(MavenUrl.from_name(name, repository_base, NAME_DELIMITER).base).css("a").filter_map do |a|
      a.text.chomp("/") if a.text.ends_with?("/") && a.text != "../"
    end
  end
end
