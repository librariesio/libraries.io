require 'uri'

module ApplicationHelper
  include SanitizeUrl

  def colours
    Languages::Language.all.map(&:color).compact.uniq.shuffle(random: Random.new(12))
  end

  def sort_options
    [
      ['Relevance', nil],
      ['SourceRank', 'rank'],
      ['GitHub Stars', 'stars'],
      ['Dependents', 'dependents_count'],
      ['Most Used', 'dependent_repos_count'],
      ['Latest Release', 'latest_release_published_at'],
      ['Contributors', 'github_contributions_count'],
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

  def rss_url(project)
    if project.versions.size > 0
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

  def linked_repo_keywords(keywords)
    keywords.compact.delete_if(&:empty?).map{|k| link_to k, "/github/search?keywords=#{k}" }.join(', ').html_safe
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
      emoji = Emoji.find_by_alias($1)
      if emoji
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
    library_text = [project.language, "library"].compact.join(' ').with_indefinite_article
    text + " - #{library_text} on #{project.platform_name} - Libraries.io"
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
    super(*[collection_or_options, options].compact)
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
      description: "Discover open source libraries, modules and frameworks you can use in your code",
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

  def tree_path(options={})
    project_path(options.except(:kind)) + "/tree#{options[:kind].present? ? '?kind='+options[:kind] : '' }"
  end

  def version_tree_path(options={})
    version_path(options.except(:kind)) + "/tree#{options[:kind].present? ? '?kind='+options[:kind] : '' }"
  end

  def usage_cache_length(total)
    return 1 if total <= 0
    (Math.log10(total).round+1)*2
  end
end
