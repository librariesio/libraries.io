# frozen_string_literal: true

atom_feed do |feed|
  feed.title("#{@project} versions - Libraries.io")
  feed.updated(@versions[0].published_at) unless @versions.empty?

  @versions.each do |version|
    feed.entry(version, url: version_url(version.to_param)) do |entry|
      entry.title(version.number)
      entry.content "", type: "html"
      entry.author do |author|
        author.name("Libraries.io")
      end
    end
  end
end
