module DependencyMiner
  def mine_dependencies
    return if scm == 'hg' # only works with git repositories at the moment
    return if fork?

    tmp_dir_name = "#{host_type}-#{owner_name}-#{project_name}".downcase

    tmp_path = Rails.root.join("tmp/#{tmp_dir_name}")

    # download code
    system "git clone -b #{default_branch} --single-branch #{url} #{tmp_path}"

    return unless tmp_path.exist? # handle failed clones

    # mine dependency activity from git repository
    miner = RepoMiner::Repository.new(tmp_path.to_s)

    # Find last commit analysed
    last_commit_sha = dependency_activities.order('committed_at DESC').first.try(:commit_sha)

    # store activities as DependencyActivity records
    commits = miner.analyse(default_branch, last_commit_sha)

    # only consider commits with dependency data
    dependency_commits = commits.select{|c| c.data[:dependencies].present? }

    activities = []
    if dependency_commits.any?
      dependency_commits.each do |commit|
        dependency_data = commit.data[:dependencies]

        dependency_data[:added_manifests].each do |added_manifest|
          added_manifest[:added_dependencies].each do |added_dependency|
            activities << format_activity(commit, added_manifest, added_dependency, 'added')
          end
        end

        dependency_data[:modified_manifests].each do |modified_manifest|
          modified_manifest[:added_dependencies].each do |added_dependency|
            activities << format_activity(commit, modified_manifest, added_dependency, 'added')
          end

          modified_manifest[:modified_dependencies].each do |modified_dependency|
            activities << format_activity(commit, modified_manifest, modified_dependency, 'modified')
          end

          modified_manifest[:removed_dependencies].each do |removed_dependency|
            activities << format_activity(commit, modified_manifest, removed_dependency, 'removed')
          end
        end

        dependency_data[:removed_manifests].each do |removed_manifest|
          removed_manifest[:removed_dependencies].each do |removed_dependency|
            activities << format_activity(commit, removed_manifest, removed_dependency, 'removed')
          end
        end
      end
    end

    # write activities to the database
    DependencyActivity.import(activities.map{|a| DependencyActivity.new(a) })



  ensure
    # delete code
    `rm -rf #{tmp_path}`
  end

  def find_project_id(project_name, platform)
    project_id = Project.platform(platform).where(name: project_name.try(:strip)).limit(1).pluck(:id).first
    return project_id if project_id
    Project.lower_platform(platform).lower_name(project_name.try(:strip)).limit(1).pluck(:id).first
  end

  def format_activity(commit, manifest, dependency, action)
    {
      repository_id: id,
      project_id: find_project_id(dependency[:name], manifest[:platform]),
      action: action,
      project_name: dependency[:name],
      commit_message: commit.message,
      requirement: dependency[:requirement],
      kind: dependency[:type],
      manifest_path: manifest[:path],
      manifest_kind: manifest[:kind],
      commit_sha: commit.sha,
      platform: manifest[:platform],
      previous_requirement: dependency[:previous_requirement],
      previous_kind: dependency[:previous_type],
      committed_at: commit.timestamp
    }
  end
end
