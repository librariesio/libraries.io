# frozen_string_literal: true

class Repository::PersistRepositoryFromUpstream
  def self.create_or_update_from_host_data(upstream_raw_host_data)
    return unless upstream_raw_host_data

    ActiveRecord::Base.transaction do
      existing_repo = find_repository_from_host_data(upstream_raw_host_data)

      if existing_repo.nil?
        new_repository = Repository.new(uuid: upstream_raw_host_data.repository_uuid, full_name: upstream_raw_host_data.full_name)

        new_repository.assign_attributes(raw_data_repository_attrs(upstream_raw_host_data))

        new_repository.save ? new_repository : nil
      else
        update_from_host_data(existing_repo, upstream_raw_host_data)
      end
    end
  end

  def self.update_from_host_data(repository, upstream_raw_host_data)
    return unless upstream_raw_host_data.present?

    if repository.full_name.downcase != upstream_raw_host_data.full_name.downcase
      remove_repository_name_clash(upstream_raw_host_data.host_type, upstream_raw_host_data.full_name)
    end

    # set unmaintained status for the Repository based on if the repository has been archived upstream
    # if the Repository already has another status then just leave it alone
    repository.status = correct_status_from_upstream(repository, archived_upstream: upstream_raw_host_data.archived)
    repository.assign_attributes(raw_data_repository_attrs(upstream_raw_host_data))
    # TODO: do we need this?
    repository.full_name = upstream_raw_host_data.full_name if repository.lower_name != upstream_raw_host_data.lower_name
    repository.uuid = upstream_raw_host_data.repository_uuid if repository.uuid.nil?

    if repository.changed?
      repository.save ? repository : nil
    else
      repository
    end
  end

  def self.find_repository_from_host_data(upstream_raw_host_data)
    existing_repo = Repository.where(host_type: (upstream_raw_host_data.host_type || "GitHub")).find_by(uuid: upstream_raw_host_data.repository_uuid)
    existing_repo = Repository.host(upstream_raw_host_data.host_type || "GitHub").find_by("lower(full_name) = ?", upstream_raw_host_data.lower_name) if existing_repo.nil?

    existing_repo
  end

  def self.remove_repository_name_clash(host_type, full_name)
    # TODO: work on refactoring this out of this class and handle it in another process
    clash = Repository.host(host_type).where("lower(full_name) = ?", full_name.downcase).first

    return unless clash
    # skip if the repository host still provides info for the clash and it is not marked as removed
    return if clash.update_from_repository && clash.status != "Removed"

    StructuredLog.capture("REMOVE_REPOSITORY_BY_NAME_CLASH",
                          {
                            repository_full_name: clash.full_name,
                            repository_host_type: clash.host_type,
                            repository_status: clash.status,
                          }.merge(clash.attributes))
    clash.destroy
  end

  def self.raw_data_repository_attrs(raw_upstream_data)
    attrs = {
      default_branch: raw_upstream_data.default_branch,
      description: raw_upstream_data.description,
      fork: raw_upstream_data.fork,
      fork_policy: raw_upstream_data.fork_policy,
      forks_count: raw_upstream_data.forks_count,
      full_name: raw_upstream_data.full_name,
      has_issues: raw_upstream_data.has_issues,
      has_pages: raw_upstream_data.has_pages,
      has_wiki: raw_upstream_data.has_wiki,
      homepage: raw_upstream_data.homepage,
      host_type: raw_upstream_data.host_type,
      keywords: raw_upstream_data.keywords,
      language: raw_upstream_data.language,
      license: raw_upstream_data.formatted_license,
      logo_url: raw_upstream_data.logo_url,
      mirror_url: raw_upstream_data.mirror_url,
      name: raw_upstream_data.name,
      open_issues_count: raw_upstream_data.open_issues_count,
      private: raw_upstream_data.is_private,
      pull_requests_enabled: raw_upstream_data.pull_requests_enabled&.to_s,
      pushed_at: raw_upstream_data.pushed_at,
      scm: raw_upstream_data.scm,
      size: raw_upstream_data.repository_size,
      stargazers_count: raw_upstream_data.stargazers_count,
      subscribers_count: raw_upstream_data.subscribers_count,
      uuid: raw_upstream_data.repository_uuid,
    }
    attrs[:source_name] = raw_upstream_data.source_name if raw_upstream_data.fork

    attrs
  end

  # Suggest the correct Repository status based on if the upstream repository data
  # indicates it should be and the current status set on this Repository.
  def self.correct_status_from_upstream(repository, archived_upstream:)
    if archived_upstream && repository.status.nil?
      StructuredLog.capture("REPOSITORY_SET_UNMAINTAINED_STATUS",
                            {
                              repository_host: repository.host_type,
                              repository_id: repository.id,
                              full_name: repository.full_name,
                            })
      # set to unmaintained if we do not have another status already assigned
      "Unmaintained"
    elsif !archived_upstream && %w[Unmaintained Removed].include?(repository.status)
      StructuredLog.capture("REPOSITORY_UNSETTING_STATUS",
                            {
                              repository_host: repository.host_type,
                              repository_id: repository.id,
                              full_name: repository.full_name,
                              current_status: repository.status,
                            })

      # set back to nil if we currently have it marked as unmaintained
      nil
    else
      # return the original status so it is not updated
      repository.status
    end
  end
end
