module RepoManifests
  def download_manifests(token = nil)
    file_list = get_file_list(token)
    return if file_list.blank?
    new_manifests = parse_manifests(file_list, token)
    sync_metadata(file_list)

    return if new_manifests.blank?

    new_manifests.each {|m| sync_manifest(m) }

    delete_old_manifests(new_manifests)

    repository_subscriptions.each(&:update_subscriptions)
  end

  def parse_manifests(file_list, token = nil)
    manifest_paths = Bibliothecary.identify_manifests(file_list)

    manifest_paths.map do |manifest_path|
      file = get_file_contents(manifest_path, token)
      if file.present? && file[:content].present?
        begin
          manifest = Bibliothecary.analyse_file(manifest_path, file[:content]).first
          manifest.merge!(sha: file[:sha]) if manifest
          manifest
        rescue
          nil
        end
      end
    end.reject(&:blank?)
  end

  def sync_metadata(file_list)
    return if file_list.nil?
    self.has_readme       = file_list.find{|file| file.match(/^README/i) }
    self.has_changelog    = file_list.find{|file| file.match(/^CHANGE|^HISTORY/i) }
    self.has_contributing = file_list.find{|file| file.match(/^(docs\/)?(.github\/)?CONTRIBUTING/i) }
    self.has_license      = file_list.find{|file| file.match(/^LICENSE|^COPYING|^MIT-LICENSE/i) }
    self.has_coc          = file_list.find{|file| file.match(/^(docs\/)?(.github\/)?CODE[-_]OF[-_]CONDUCT/i) }
    self.has_threat_model = file_list.find{|file| file.match(/^THREAT[-_]MODEL/i) }
    self.has_audit        = file_list.find{|file| file.match(/^AUDIT/i) }
    save if self.changed?
  end

  def sync_manifest(m)
    args = {platform: m[:platform], kind: m[:kind], filepath: m[:path], sha: m[:sha]}

    unless manifests.find_by(args)
      manifest = manifests.create(args)
      dependencies = m[:dependencies].map(&:with_indifferent_access).uniq{|dep| [dep[:name].try(:strip), dep[:requirement], dep[:type]]}
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
    to_be_removed = existing_manifests - new_manifests.map{|m| [m[:platform], m[:path]] }
    to_be_removed.each do |m|
      manifests.where(platform: m[0], filepath: m[1]).each(&:destroy)
    end
    manifests.where.not(id: manifests.latest.map(&:id)).each(&:destroy)
  end
end
