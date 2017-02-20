module BitbucketRepository
  extend ActiveSupport::Concern

  included do
    IGNORABLE_BITBUCKET_EXCEPTIONS = [BitBucket::Error::NotFound, BitBucket::Error::Forbidden]

    def self.create_from_bitbucket(full_name, token = nil)
      repo_hash = map_from_bitbucket(full_name, token)
      create_from_hash(repo_hash)
    rescue *IGNORABLE_BITBUCKET_EXCEPTIONS
      nil
    end

    def self.bitbucket_client(token = nil)
      BitBucket.new oauth_token: token || ENV['BITBUCKET_KEY']
    end

    def self.map_from_bitbucket(full_name, token = nil)
      client = bitbucket_client(token)
      user_name, repo_name = full_name.split('/')
      project = client.repos.get(user_name, repo_name)
      v1_project = client.repos.get(user_name, repo_name, api_version: '1.0')
      repo_hash = project.to_hash.with_indifferent_access.slice(:description, :language, :full_name, :name, :has_wiki, :has_issues, :scm)

      repo_hash.merge!({
        id: project.uuid,
        host_type: 'Bitbucket',
        owner: {},
        homepage: project.website,
        fork: project.parent.present?,
        created_at: project.created_on,
        updated_at: project.updated_on,
        subscribers_count: v1_project.followers_count,
        forks_count: v1_project.forks_count,
        private: project.is_private,
        size: project[:size].to_f/1000,
        parent: {
          full_name: project.fetch('parent', {}).fetch('full_name', nil)
        }
      })
    end

    def self.recursive_bitbucket_repos(url, limit = 10)
      return if limit.zero?
      r = Typhoeus::Request.new(url,
        method: :get,
        headers: { 'Accept' => 'application/json' }).run

      json = Oj.load(r.body)

      json['values'].each do |repo|
        CreateRepositoryWorker.perform_async('Bitbucket', repo['full_name'])
      end
      puts json['next']
      if json['values'].any? && json['next']
        limit = limit - 1
        REDIS.set 'bitbucket-after', Addressable::URI.parse(json['next']).query_values['after']
        recursive_bitbucket_repos(json['next'], limit)
      end
    end
  end

  def bitbucket_client(token = nil)
    Repository.bitbucket_client(token)
  end

  def download_bitbucket_fork_source(token = nil)
    return true unless self.fork? && self.source.nil?
    Repository.create_from_bitbucket(source_name, token)
  end

  def download_bitbucket_readme(token = nil)
    user_name, repo_name = full_name.split('/')
    files = bitbucket_client(token).repos.sources.list(user_name, repo_name, 'master', '/')
    paths =  files.files.map(&:path)
    readme_path = paths.select{|path| path.match(/^readme/i) }.first
    return if readme_path.nil?
    raw_content = bitbucket_client(token).repos.sources.list(user_name, repo_name, 'master', readme_path).data
    contents = {
      html_body: GitHub::Markup.render(readme_path, raw_content)
    }

    if readme.nil?
      create_readme(contents)
    else
      readme.update_attributes(contents)
    end
  rescue *IGNORABLE_BITBUCKET_EXCEPTIONS
    nil
  end

  def download_bitbucket_tags(token = nil)
    user_name, repo_name = full_name.split('/')
    remote_tags = bitbucket_client(token).repos.tags(user_name, repo_name)
    existing_tag_names = tags.pluck(:name)
    remote_tags.each do |name, data|
      next if existing_tag_names.include?(name)
      tags.create({
        name: name,
        kind: "tag",
        sha: data.raw_node,
        published_at: data.utctimestamp
      })
    end
  rescue *IGNORABLE_BITBUCKET_EXCEPTIONS
    nil
  end

  def bitbucket_avatar_url(size = 60)
    "https://bitbucket.org/#{full_name}/avatar/#{size}"
  end

  def get_bitbucket_file_list(token = nil)
    bitbucket_client(token).get_request("1.0/repositories/#{full_name}/directory/")[:values]
  end

  def get_bitbucket_file_contents(path, token = nil)
    user_name, repo_name = full_name.split('/')
    bitbucket_client(token).repos.sources.list(user_name, repo_name, 'master', path).data
  end

  def update_from_bitbucket(token = nil)
    begin
      r = Repository.map_from_bitbucket(self.full_name)
      return unless r.present?
      self.uuid = r[:id] unless self.uuid == r[:id]
       if self.full_name.downcase != r[:full_name].downcase
         clash = Repository.host(r[:host_type]).where('lower(full_name) = ?', r[:full_name].downcase).first
         if clash && (!clash.update_from_bitbucket(token) || clash.status == "Removed")
           clash.destroy
         end
         self.full_name = r[:full_name]
       end
      self.owner_id = r[:owner][:id]
      self.license = Project.format_license(r[:license][:key]) if r[:license]
      self.source_name = r[:parent][:full_name] if r[:fork]
      assign_attributes r.slice(*Repository::API_FIELDS)
      save! if self.changed?
    rescue BitBucket::Error::NotFound
      update_attribute(:status, 'Removed') if !self.private?
    rescue *IGNORABLE_BITBUCKET_EXCEPTIONS
      nil
    end
  end
end
