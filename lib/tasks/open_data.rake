require 'csv'

namespace :open_data do
  task export: :environment do
    version = '1.0.0'
    date = Date.today.to_s(:db)

    # Projects
    csv_file = File.open("data/projects-#{version}-#{date}.csv",'w')
    csv_file = CSV.new(csv_file)
    csv_file << [
      'Platform',
      'Name',
      'created_at',
      'updated_at',
      'description',
      'keywords',
      'homepage',
      'licenses',
      'repository_url',
      'normalized_licenses',
      'versions_count',
      'rank',
      'latest_release_published_at',
      'latest_release_number',
      'pm_id',
      'keywords_array',
      'dependents_count',
      'language',
      'status',
      'last_synced_at',
      'dependent_repos_count'
    ]

    Project.not_removed.find_each do |project|
      csv_file << [
        project.platform,
        project.name,
        project.created_at,
        project.updated_at,
        project.description,
        project.keywords,
        project.homepage,
        project.licenses,
        project.repository_url,
        project.normalized_licenses,
        project.versions_count,
        project.rank,
        project.latest_release_published_at,
        project.latest_release_number,
        project.pm_id,
        project.keywords_array,
        project.dependents_count,
        project.language,
        project.status,
        project.last_synced_at,
        project.dependent_repos_count,
      ]
    end

    # Version
    csv_file = File.open("data/versions-#{version}-#{date}.csv",'w')
    csv_file = CSV.new(csv_file)
    csv_file << [
      'Platform',
      'Project Name',
      'Number',
      'Published Timestamp',
      'Created Timestamp',
      'Updated Timestamp'
    ]

    Project.not_removed.includes(:versions).find_each do |project|
      project.versions.each do |version|
        csv_file << [
          project.platform,
          project.name,
          version.number,
          version.published_at,
          version.created_at,
          version.updated_at
        ]
      end
    end

    # Dependencies
    csv_file = File.open("data/dependencies-#{version}-#{date}.csv",'w')
    csv_file = CSV.new(csv_file)
    csv_file << [
      'Platform',
      'Project Name',
      'Verion Number',
      'Dependency Name',
      'Dependency Platform',
      'Dependency Kind',
      'Optional Dependency',
      'Dependency Requirements'
    ]

    Project.not_removed.includes(versions: :dependencies).find_each do |project|
      project.versions.each do |version|
        version.dependencies.each do |dependency|
          csv_file << [
            project.platform,
            project.name,
            version.number,
            dependency.project_name,
            dependency.platform,
            dependency.kind,
            dependency.optional,
            dependency.requirements
          ]
        end
      end
    end

    # Repository
    csv_file = File.open("data/repositories-#{version}-#{date}.csv",'w')
    csv_file = CSV.new(csv_file)
    csv_file << [
      'Host Type',
      'Name with Owner',
      'full_name',
      'description',
      'fork',
      'created_at',
      'updated_at',
      'pushed_at',
      'homepage',
      'size',
      'stargazers_count',
      'language',
      'has_issues',
      'has_wiki',
      'has_pages',
      'forks_count',
      'mirror_url',
      'open_issues_count',
      'default_branch',
      'subscribers_count',
      'uuid',
      'source_name',
      'license',
      'contributions_count',
      'has_readme',
      'has_changelog',
      'has_contributing',
      'has_license',
      'has_coc',
      'has_threat_model',
      'has_audit',
      'status',
      'last_synced_at',
      'rank',
      'host_type',
      'host_domain',
      'name',
      'scm',
      'fork_policy',
      'pull_requests_enabled',
      'logo_url',
      'keywords'
    ]

    Repository.open_source.not_removed.find_each do |repo|
      csv_file << [
        repo.host_type,
        repo.full_name,
        repo.full_name,
        repo.description,
        repo.fork,
        repo.created_at,
        repo.updated_at,
        repo.pushed_at,
        repo.homepage,
        repo.size,
        repo.stargazers_count,
        repo.language,
        repo.has_issues,
        repo.has_wiki,
        repo.has_pages,
        repo.forks_count,
        repo.mirror_url,
        repo.open_issues_count,
        repo.default_branch,
        repo.subscribers_count,
        repo.uuid,
        repo.source_name,
        repo.license,
        repo.contributions_count,
        repo.has_readme,
        repo.has_changelog,
        repo.has_contributing,
        repo.has_license,
        repo.has_coc,
        repo.has_threat_model,
        repo.has_audit,
        repo.status,
        repo.last_synced_at,
        repo.rank,
        repo.host_type,
        repo.host_domain,
        repo.name,
        repo.scm,
        repo.fork_policy,
        repo.pull_requests_enabled,
        repo.logo_url,
        repo.keywords,
      ]
    end

    # Tags
    csv_file = File.open("data/tags-#{version}-#{date}.csv",'w')
    csv_file = CSV.new(csv_file)
    csv_file << [
      'Host Type',
      'Repository Name with Owner',
      'Tag Name',
      'Tag git sha',
      'Tag kind',
      'published_at',
      'created_at',
      'updated_at'
    ]

    Repository.open_source.not_removed.includes(:tags).find_each do |repo|
      repo.tags.each do |tag|
        csv_file << [
          repo.host_type,
          repo.full_name,
          tag.name,
          tag.sha,
          tag.kind,
          tag.published_at,
          tag.created_at,
          tag.updated_at
        ]
      end
    end

    # Repository Dependencies
    csv_file = File.open("data/repository_dependencies-#{version}-#{date}.csv",'w')
    csv_file = CSV.new(csv_file)
    csv_file << [
      'Host Type',
      'Repository Name with Owner',
      'manifest.platform',
      'manifest.filepath',
      'manifest.branch',
      'manifest.kind',
      'repository_dependency.optional',
      'repository_dependency.project_name',
      'repository_dependency.requirements',
      'repository_dependency.kind'
    ]

    Repository.open_source.not_removed.includes(manifests: :repository_dependencies).find_each do |repo|
      repo.manifests.each do |manifest|
        manifest.repository_dependencies.each do |repository_dependency|
          csv_file << [
            repo.host_type,
            repo.full_name,
            manifest.platform,
            manifest.filepath,
            manifest.branch,
            manifest.kind,
            repository_dependency.optional,
            repository_dependency.project_name,
            repository_dependency.requirements,
            repository_dependency.kind
          ]
        end
      end
    end
  end
end
