require 'uri'

module ApplicationHelper
  include SanitizeUrl

  def sort_options
    [
      ['Relevance', nil],
      ['SourceRank', 'rank'],
      ['GitHub Stars', 'stars'],
      ['Dependents', 'dependents_count'],
      ['Latest Release', 'latest_release_published_at'],
      ['Newest', 'created_at']
    ]
  end

  def repo_sort_options
    [
      ['Relevance', nil],
      ['Stars', 'stargazers_count'],
      ['Forks', 'forks_count'],
      ['Watchers', 'subscribers_count'],
      ['Open issues', 'open_issues_count'],
      ['Contributors', 'github_contributions_count'],
      ['Repo size', 'size'],
      ['Newest', 'created_at'],
      ['Recently pushed', 'pushed_at']
    ]
  end

  def package_link(project, version = nil)
    Repositories::Base.package_link(project, version)
  end

  def download_url(name, platform, version = nil)
    case platform
    when 'Rubygems'
      "https://rubygems.org/downloads/#{name}-#{version}.gem"
    when 'Atom'
      "https://www.atom.io/api/packages/#{name}/versions/#{version}/tarball"
    when 'Cargo'
      "https://crates.io/api/v1/crates/#{name}/#{version}/download"
    when 'CRAN'
      "https://cran.r-project.org/src/contrib/#{name}_#{version}.tar.gz"
    when 'Emacs'
      "http://melpa.org/packages/#{name}-#{version}.tar"
    when 'Hackage'
      "http://hackage.haskell.org/package/#{name}-#{version}/#{name}-#{version}.tar.gz"
    end
  end

  def documentation_url(name, platform, version = nil)
    case platform
    when 'Rubygems'
      "http://www.rubydoc.info/gems/#{name}/#{version}"
    when 'Go'
      "http://godoc.org/#{name}"
    when 'Pub'
      "http://www.dartdocs.org/documentation/#{name}/#{version}"
    when 'CRAN'
      "http://cran.r-project.org/web/packages/#{name}/#{name}.pdf"
    when 'Hex'
      "http://hexdocs.pm/#{name}/#{version}"
    when 'CocoaPods'
      "http://cocoadocs.org/docsets/#{name}/#{version}"
    end
  end

  def install_instructions(project, platform, version = nil)
    name = project.name
    case platform
    when 'Rubygems'
      "gem install #{name}" + (version ? " -v #{version}" : "")
    when 'NPM'
      "npm install #{name}" + (version ? "@#{version}" : "")
    when 'Jam'
      "jam install #{name}" + (version ? "@#{version}" : "")
    when 'Bower'
      "bower install #{name}" + (version ? "##{version}" : "")
    when 'Dub'
      "dub fetch #{name}" + (version ? " --version #{version}" : "")
    when 'Hackage'
      "cabal install #{name}" + (version ? "-#{version}" : "")
    when 'PyPi'
      "pip install #{name}" + (version ? "==#{version}" : "")
    when 'Atom'
      "apm install #{name}" + (version ? "@#{version}" : "")
    when 'Nimble'
      "nimble install #{name}" + (version ? "@##{version}" : "")
    when 'Go'
      "go get #{name}"
    when 'NuGet'
      "Install-Package #{name}" + (version ? " -Version #{version}" : "")
    when 'Meteor'
      "meteor add #{name}" + (version ? "@=#{version}" : "")
    when 'Elm'
      "elm-package install #{name} #{version}"
    when 'PlatformIO'
      "platformio lib install #{project.pm_id}"
    when 'Inqlude'
      "inqlude install #{name}"
    when 'Homebrew'
      "brew install #{name}"
    end
  end

  def rss_url(project)
    if project.versions.count > 0
      project_versions_url({format: "atom"}.merge(project.to_param))
    elsif project.github_repository && project.github_tags.length > 0
      project_tags_url({format: "atom"}.merge(project.to_param))
    end
  end

  def title(page_title)
    content_for(:title) { page_title }
    page_title
  end

  def description(page_description)
    content_for(:description) { truncate(page_description, length: 160) }
  end

  def linked_licenses(licenses)
    return 'Unknown' if licenses.compact.empty?
    licenses.compact.delete_if(&:empty?).map{|l| link_to format_license(l), license_path(l) }.join('/').html_safe
  end

  def about_licenses(licenses)
    licenses.compact.delete_if(&:empty?).map{|l| format_license(l) }.join(' or ')
  end

  def linked_keywords(keywords)
    keywords.compact.delete_if(&:empty?).map{|k| link_to k, "/keywords/#{k}" }.join(', ').html_safe
  end

  def platform_name(platform)
    if platform.downcase == 'npm'
      return 'npm'
    elsif platform.downcase == 'wordpress'
      return 'WordPress'
    else
      return platform
    end
  end

  def favicon(size)
    libicon = "https://libicons.herokuapp.com/favicon.ico"
    @color ? "#{libicon}?hex=#{URI::escape(@color)}&size=#{size}" : "/favicon-#{size}.png"
  end

  def format_license(license)
    return 'Unknown' if license.blank?
    Project.format_license(license)
  end

  def format_language(language)
    return nil if language.blank?
    Languages::Language[language].try(:to_s)
  end

  def stats_for(title, records)
    render 'table', title: title, records: records
  end

  def emojify(content)
    h(content).to_str.gsub(/:([\w+-]+):/) do |match|
      if emoji = Emoji.find_by_alias($1)
        %(<img alt="#$1" src="#{image_path("emoji/#{emoji.image_filename}")}" style="vertical-align:middle" width="20" height="20" />)
      else
        match
      end
    end.html_safe if content.present?
  rescue
    content
  end

  def feature_flag(bool, negative = nil)
    icon_class = bool ? 'check' : 'times'
    color = bool ? 'green' : 'red'
    tag = content_tag :i, '', class: "fa fa-#{icon_class}", style: "color:#{color}"
    !bool && negative ? content_tag(:i, negative) : tag
  end

  def dependency_platform(platform_string)
    return platform_string if platform_string.nil?
    case platform_string.downcase
    when 'rubygemslockfile'
      'rubygems'
    when 'cocoapodslockfile'
      'cocoapods'
    when 'nugetlockfile', 'nuspec'
      'nuget'
    when 'packagistlockfile'
      'packagist'
    when 'gemspec'
      'rubygems'
    when 'npmshrinkwrap'
      'npm'
    else
      platform_string.downcase
    end
  end

  def source_path(github_repository)
    return nil unless github_repository.fork?
    if github_repository.source.present?
      github_repository_path(github_repository.source.owner_name, github_repository.source.project_name)
    else
      github_repository.source_url
    end
  end

  def github_user_title(user)
    if user.name.present? && user.name.downcase != user.login.downcase
      "#{user.name} (#{user.login})"
    else
      user.login
    end
  end

  def project_description(project, version)
    text = project.description || project.name
    text += " - #{version}" if version
    text += " - a #{project.language} library on #{project.platform_name} - Libraries.io"
  end

  def truncate_with_tip(text, length)
    if text && text.length > length
      content_tag(:span, truncate(text, length: length), class: 'tip', title: text)
    else
      text
    end
  end

  def will_paginate(collection_or_options = nil, options = {})
    if collection_or_options.is_a? Hash
      options, collection_or_options = collection_or_options, nil
    end
    unless options[:renderer]
      options = options.merge :renderer => BootstrapPagination::Rails
    end
    super *[collection_or_options, options].compact
  end

  def source_rank_badge_class(value)
    if value > 0
      'alert-success'
    elsif value < 0
      'alert-danger'
    else
      'alert-warning'
    end
  end

  def source_rank_titles
    {
      basic_info_present:         'Basic info present?',
      repository_present:         'GitHub repository present?',
      readme_present:             'Readme present?',
      license_present:            'License present?',
      versions_present:           'Has multiple versions?',
      follows_semver:             'Follows SemVer?',
      recent_release:             'Recent release?',
      not_brand_new:              'Not brand new?',
      is_deprecated:              'Deprecated?',
      is_unmaintained:            'Unmaintained?',
      is_removed:                 'Removed?',
      any_outdated_dependencies:  'Outdated dependencies?',
      one_point_oh:               '1.0.0 or greater?',
      all_prereleases:            'Prerelease?',
      github_stars:               'GitHub stars',
      dependent_projects:         'Dependent Projects',
      dependent_repositories:     'Dependent Repositories',
      contributors:               'Contributors',
      subscribers:                'Libraries.io subscribers'
    }
  end

  def source_rank_explainations
    {
      basic_info_present:         'Description, homepage/repository link and keywords present?',
      versions_present:           'Has the project had more than one release?',
      follows_semver:             'Every version has a valid SemVer number',
      recent_release:             'Within the past 6 months?',
      not_brand_new:              'Existed for at least 6 months',
      is_deprecated:              'Marked as deprecated by the maintainer',
      is_unmaintained:            'Marked as unmaintained by the maintainer',
      is_removed:                 'Removed from the package manager',
      all_prereleases:            'All versions are prerelease',
      any_outdated_dependencies:  'At least one dependency is behind the latest version',
      github_stars:               'Logarithmic scale',
      dependent_projects:         'Logarithmic scale times two',
      dependent_repositories:     'Logarithmic scale',
      contributors:               'Logarithmic scale divided by two',
      subscribers:                'Logarithmic scale divided by two'
    }
  end

  def cp(path)
    "active" if current_page?(path)
  end

  def shareable_image_url(platform)
    "https://librariesio.github.io/pictogram/#{platform.downcase}/#{platform.downcase}.png"
  end

  def render_meta(record = nil)
    render(partial: 'meta/facebook', locals: { meta: meta_tags_for(record) }) +
    render(partial: 'meta/twitter', locals: { meta: meta_tags_for(record) })
  end

  def default_meta_tags
    {
      title: "Libraries - The Open Source Discovery Service",
      url: "https://libraries.io",
      description: "Discover new modules and libraries you can use in your projects",
      image: "https://libraries.io/apple-touch-icon-152x152.png",
      site_name: "Libraries.io",
      site_twitter: "@librariesio"
    }
  end

  def meta_tags_for(record)
    return default_meta_tags if record.nil?
    case record.class.name
    when 'Project'
      hash = record.meta_tags.merge({
        url: project_url(record.to_param),
        image: shareable_image_url(record.platform)
      })
    when 'GithubRepository'
      hash = record.meta_tags.merge({
        url: github_repository_url(record.owner_name, record.project_name)
      })
    when 'GithubUser', 'GithubOrganisation'
      hash = record.meta_tags.merge({
        url: user_url(record.login)
      })
    else
      hash = {}
    end
    default_meta_tags.merge(hash)
  end

  def featured_orgs
    ['ebayinc','ibm','cloudant','microsoft', 'hmrc','dpspublishing', 'clearleft',
     'google','thoughtworks','yelp','alphagov','nbcnews','openshift', 'ansible',
     'heroku','github','thoughtbot','shopify','travis-ci','redhat-developer',
     'mozilla','django','jenkinsci','the-economist-editorial','angular','emberjs',
     'nearform','futurelearn','scaleway','producthunt','mysociety','sublimetext',
     'codeforamerica','cdnjs','nodejs', 'simpleweb','mashape','yeoman','src-d',
     'ustwo','coderdojo','cfibmers','keystonejs','tableflip','teamtito','codacy',
     'saltstack','baremetrics','vmware','uswitch','gocardless','ucl','Leanstack',
     'airbrake','18f','joyent','liferay']
  end
end
