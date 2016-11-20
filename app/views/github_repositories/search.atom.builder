atom_feed do |feed|
  feed.title(@title)
  feed.updated(@github_repositories[0].try(:created_at)) if @github_repositories.length > 0

  @github_repositories.each do |github_repository|
    feed.entry(github_repository, url: github_repository_url(github_repository.owner_name, github_repository.project_name)) do |entry|
      entry.title(github_repository.full_name)
      entry.content(github_repository.description, type: 'html')
      entry.author do |author|
        author.name('Libraries.io')
      end
    end
  end
end
