# frozen_string_literal: true
atom_feed do |feed|
  feed.title(@title)
  feed.updated(@repositories[0].try(:created_at)) if @repositories.length > 0

  @repositories.each do |repository|
    feed.entry(repository, url: repository_url(repository.to_param)) do |entry|
      entry.title(repository.full_name)
      entry.content(repository.description, type: 'html')
      entry.author do |author|
        author.name('Libraries.io')
      end
    end
  end
end
