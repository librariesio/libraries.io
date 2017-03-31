module Profile
  def top_favourite_projects
    Project.where(id: top_favourite_project_ids).maintained.order("position(','||projects.id::text||',' in '#{top_favourite_project_ids.join(',')}')")
  end

  def top_favourite_project_ids
    Rails.cache.fetch "org:#{self.id}:top_favourite_project_ids:v2", :expires_in => 1.week, race_condition_ttl: 2.minutes do
      favourite_projects.limit(10).pluck(:id)
    end
  end

  def top_contributors
    RepositoryUser.where(id: top_contributor_ids).order("position(','||repository_users.id::text||',' in '#{top_contributor_ids.join(',')}')")
  end

  def top_contributor_ids
    Rails.cache.fetch "org:#{self.id}:top_contributor_ids", :expires_in => 1.week, race_condition_ttl: 2.minutes do
      contributors.visible.limit(50).pluck(:id)
    end
  end

  def avatar_url(size = 60)
    "https://avatars.githubusercontent.com/u/#{github_id}?size=#{size}"
  end

  def github_url
    "https://github.com/#{login}"
  end

  def to_s
    name.presence || login
  end

  def to_param
    login
  end
end
