module RepoTags
  def download_tags(token = nil)
    existing_tag_names = github_tags.pluck(:name)
    github_client(token).refs(full_name, 'tags').each do |tag|
      next unless tag['ref']
      download_tag(token, tag, existing_tag_names)
    end
  rescue *GithubRepository::IGNORABLE_GITHUB_EXCEPTIONS
    nil
  end

  def download_tag(token, tag, existing_tag_names)
    match = tag.ref.match(/refs\/tags\/(.*)/)
    return unless match
    name = match[1]
    return if existing_tag_names.include?(name)

    object = github_client(token).get(tag.object.url)

    tag_hash = {
      name: name,
      kind: tag.object.type,
      sha: tag.object.sha
    }

    case tag.object.type
    when 'commit'
      tag_hash[:published_at] = object.committer.date
    when 'tag'
      tag_hash[:published_at] = object.tagger.date
    end

    github_tags.create!(tag_hash)
  end
end
