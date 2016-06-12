atom_feed do |feed|
  feed.title("#{@user}'s version feed - Libraries.io")
  feed.updated(@versions[0].published_at) if @versions.size > 0

  @versions.each do |version|
    feed.entry(version, url: version_url(version.to_param)) do |entry|
      entry.title "#{version.project.name} - #{version.number}"
      entry.published Time.at(version.published_at).rfc822
      entry.content render(:partial => 'new_version', locals: {version: version, user: @user}), :type => "html"
      entry.author do |author|
        author.name('Libraries.io')
      end
    end
  end
end
