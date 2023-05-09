# frozen_string_literal: true

atom_feed do |feed|
  feed.title("#{@project} tags - Libraries.io")
  feed.updated(@tags[0].published_at) if @tags.length > 0

  @tags.each do |tag|
    feed.entry(tag, url: version_url(@project.to_param.merge(number: tag.name))) do |entry|
      entry.title(tag.number)
      entry.published Time.at(tag.published_at).rfc822
      entry.content "", type: "html"
      entry.author do |author|
        author.name("Libraries.io")
      end
    end
  end
end
