module RepositoryHost
  class Bitbucket < Base
    IGNORABLE_EXCEPTIONS = [BitBucket::Error::NotFound, BitBucket::Error::Forbidden]

    def avatar_url(size = 60)
      "https://bitbucket.org/#{repository.full_name}/avatar/#{size}"
    end

    def download_fork_source(token = nil)
      super
      Repository.create_from_bitbucket(repository.source_name, token)
    end

    def download_readme(token = nil)
      user_name, repo_name = repository.full_name.split('/')
      files = api_client(token).repos.sources.list(user_name, repo_name, 'master', '/')
      paths =  files.files.map(&:path)
      readme_path = paths.select{|path| path.match(/^readme/i) }.first
      return if readme_path.nil?
      raw_content = api_client(token).repos.sources.list(user_name, repo_name, 'master', readme_path).data
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
      user_name, repo_name = repository.full_name.split('/')
      remote_tags = api_client(token).repos.tags(user_name, repo_name)
      existing_tag_names = repository.tags.pluck(:name)
      remote_tags.each do |name, data|
        next if existing_tag_names.include?(name)
        repository.tags.create({
          name: name,
          kind: "tag",
          sha: data.raw_node,
          published_at: data.utctimestamp
        })
      end
    rescue *IGNORABLE_EXCEPTIONS
      nil
    end

    private

    def api_client(token = nil)
      BitBucket.new oauth_token: token || ENV['BITBUCKET_KEY']
    end
  end
end
