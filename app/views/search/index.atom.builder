# frozen_string_literal: true

atom_feed do |feed|
  feed.title(@title)
  feed.updated(@projects[0].created_at) if @projects.length > 0

  @projects.each do |project|
    feed.entry(project, url: project_url(project.to_param)) do |entry|
      entry.title(project.name)
      entry.content(project.description, type: "html")
      entry.author do |author|
        author.name("Libraries.io")
      end
    end
  end
end
