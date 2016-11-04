module RepoManifests
  def download_manifests(token = nil)
    body = parse_manifests(token)

    if body
      new_manifests = body["manifests"]
      sync_metadata(body)
    else
      new_manifests = nil
    end

    return if new_manifests.nil?

    new_manifests.each {|m| sync_manifest(m) }

    delete_old_manifests(new_manifests)

    repository_subscriptions.each(&:update_subscriptions)
  end

  def parse_manifests(token)
    r = Typhoeus::Request.new("http://librarian.libraries.io/v2/repos/#{full_name}",
      method: :get,
      params: { token: token },
      headers: { 'Accept' => 'application/json' }).run
    begin
      Oj.load(r.body)
    rescue Oj::ParseError
      nil
    end
  end

  def sync_metadata(body)
    if body && body['metadata']
      meta = body['metadata']

      self.has_readme       = meta['readme']['path']        if meta['readme']
      self.has_changelog    = meta['changelog']['path']     if meta['changelog']
      self.has_contributing = meta['contributing']['path']  if meta['contributing']
      self.has_license      = meta['license']['path']       if meta['license']
      self.has_coc          = meta['codeofconduct']['path'] if meta['codeofconduct']
      self.has_threat_model = meta['threatmodel']['path']   if meta['threatmodel']
      self.has_audit        = meta['audit']['path']         if meta['audit']

      save! if self.changed?
    end
  end

  def sync_manifest(m)
    args = {platform: m['platform'], kind: m['type'], filepath: m['filepath'], sha: m['sha']}

    unless manifests.find_by(args)
      manifest = manifests.create(args)
      dependencies = m['dependencies'].uniq{|dep| [dep['name'].try(:strip), dep['version'], dep['type']]}
      dependencies.each do |dep|
        platform = manifest.platform
        next unless dep.is_a?(Hash)
        project = Project.platform(platform).find_by_name(dep['name'])

        manifest.repository_dependencies.create({
          project_id: project.try(:id),
          project_name: dep['name'].try(:strip),
          platform: platform,
          requirements: dep['version'],
          kind: dep['type']
        })
      end
    end
  end

  def delete_old_manifests(new_manifests)
    existing_manifests = manifests.map{|m| [m.platform, m.filepath] }
    to_be_removed = existing_manifests - new_manifests.map{|m| [m["platform"], m["filepath"]] }
    to_be_removed.each do |m|
      manifests.where(platform: m[0], filepath: m[1]).each(&:destroy)
    end
    manifests.where.not(id: manifests.latest.map(&:id)).each(&:destroy)
  end
end
