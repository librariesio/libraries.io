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
    elsif platform.downcase == 'biicode'
      return 'biicode'
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
end
