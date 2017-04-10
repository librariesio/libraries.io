module RepositoryOwner
  class Base
    attr_reader :owner

    def initialize(owner)
      @owner = owner
    end

    def avatar_url(size = 60)
      raise NotImplementedError
    end

    def repository_url
      raise NotImplementedError
    end

    def top_favourite_projects
      Project.where(id: top_favourite_project_ids).maintained.order("position(','||projects.id::text||',' in '#{top_favourite_project_ids.join(',')}')")
    end

    def top_contributors
      RepositoryUser.where(id: top_contributor_ids).order("position(','||repository_users.id::text||',' in '#{top_contributor_ids.join(',')}')")
    end

    def to_s
      owner.name.presence || owner.login
    end

    def to_param
      owner.login
    end

    def github_id
      owner.uuid
    end

    private

    def top_favourite_project_ids
      Rails.cache.fetch "org:#{owner.id}:top_favourite_project_ids:v2", :expires_in => 1.week, race_condition_ttl: 2.minutes do
        owner.favourite_projects.limit(10).pluck(:id)
      end
    end


    def top_contributor_ids
      Rails.cache.fetch "org:#{owner.id}:top_contributor_ids", :expires_in => 1.week, race_condition_ttl: 2.minutes do
        owner.contributors.visible.limit(50).pluck(:id)
      end
    end
  end
end
