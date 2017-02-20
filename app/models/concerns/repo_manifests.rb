module RepoManifests
  def download_manifests(token = nil)
    file_list = get_file_list(token)
    return if file_list.empty?
    new_manifests = parse_manifests(file_list, token)
    sync_metadata(file_list.map{|file| file.path })

    return if new_manifests.empty?

    new_manifests.each {|m| sync_manifest(m) }

    delete_old_manifests(new_manifests)

    repository_subscriptions.each(&:update_subscriptions)
  end

  def get_file_list(token = nil)
    case host_type
    when 'GitHub'
      get_github_file_list(token)
    when 'GitLab'
      get_gitlab_file_list(token)
    when 'Bitbucket'
      # not implemented yet
    end
  end

  def get_file_contents(path, token = nil)
    case host_type
    when 'GitHub'
      get_github_file_contents(path, token)
    when 'GitLab'
      get_gitlab_file_contents(path, token)
    when 'Bitbucket'
      # not implemented yet
    end
  end

  def parse_manifests(file_list, token = nil)
    manifest_paths = Bibliothecary.identify_manifests(file_list.map{|file| file.path })

    manifest_paths.map do |manifest_path|
      Bibliothecary.analyse_file(manifest_path, get_file_contents(manifest_path)).first
    end.reject(&:empty?)
  end

  def sync_metadata(file_list)
    self.has_readme       = file_list.any?{|file| file.match(/^README/i) }
    self.has_changelog    = file_list.any?{|file| file.match(/^CHANGELOG/i) }
    self.has_contributing = file_list.any?{|file| file.match(/^CONTRIBUTING/i) }
    self.has_license      = file_list.any?{|file| file.match(/^LICENSE/i) }
    self.has_coc          = file_list.any?{|file| file.match(/^CODE[-_]OF[-_]CONDUCT/i) }
    self.has_threat_model = file_list.any?{|file| file.match(/^THREAT[-_]MODEL/i) }
    self.has_audit        = file_list.any?{|file| file.match(/^AUDIT/i) }
    save if self.changed?
  end

  def sync_manifest(m)
    args = {platform: m[:platform], kind: m[:type], filepath: m[:path]}

    unless manifests.find_by(args)
      manifest = manifests.create(args)
      dependencies = m[:dependencies].uniq{|dep| [dep[:name].try(:strip), dep[:requirement], dep[:type]]}
      dependencies.each do |dep|
        platform = manifest.platform
        next unless dep.is_a?(Hash)
        project = Project.platform(platform).find_by_name(dep[:name])

        manifest.repository_dependencies.create({
          project_id: project.try(:id),
          project_name: dep[:name].try(:strip),
          platform: platform,
          requirements: dep[:requirement],
          kind: dep[:type]
        })
      end
    end
  end

  def delete_old_manifests(new_manifests)
    existing_manifests = manifests.map{|m| [m.platform, m.filepath] }
    to_be_removed = existing_manifests - new_manifests.map{|m| [m[:platform], m[:filepath]] }
    to_be_removed.each do |m|
      manifests.where(platform: m[0], filepath: m[1]).each(&:destroy)
    end
    manifests.where.not(id: manifests.latest.map(&:id)).each(&:destroy)
  end
end
