module RepositoryHost
  class Gitlab < Base
    IGNORABLE_EXCEPTIONS = [Gitlab::Error::NotFound, Gitlab::Error::Forbidden]

    def avatar_url(_size = 60)
      repository.logo_url
    end

    def download_fork_source(token = nil)
      super
      Repository.create_from_gitlab(repository.source_name, token)
    end

    def download_readme(token = nil)
      files = api_client(token).tree(repository.full_name.gsub('/','%2F'))
      paths =  files.map(&:path)
      readme_path = paths.select{|path| path.match(/^readme/i) }.first
      return if readme_path.nil?
      raw_content =  api_client(token).file_contents(repository.full_name.gsub('/','%2F'), readme_path)
      contents = {
        html_body: GitHub::Markup.render(readme_path, raw_content)
      }

      if repository.readme.nil?
        repository.create_readme(contents)
      else
        repository.readme.update_attributes(contents)
      end
    rescue *IGNORABLE_EXCEPTIONS
      nil
    end

    def download_tags(token = nil)
      remote_tags = api_client(token).tags(repository.full_name.gsub('/','%2F')).auto_paginate
      existing_tag_names = repository.tags.pluck(:name)
      remote_tags.each do |tag|
        next if existing_tag_names.include?(tag.name)
        repository.tags.create({
          name: tag.name,
          kind: "tag",
          sha: tag.commit.id,
          published_at: tag.commit.committed_date
        })
      end
    rescue *IGNORABLE_EXCEPTIONS
      nil
    end

    private

    def api_client(token = nil)
      Gitlab.client(endpoint: 'https://gitlab.com/api/v3', private_token: token || ENV['GITLAB_KEY'])
    end
  end
end
