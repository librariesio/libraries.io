require 'csv'

EXPORT_VERSION = '1.0.0'
EXPORT_DATE = "2017-06-14"

namespace :open_data do
  desc 'Export all open data csvs'
  task export: [
    :export_projects,
    :export_versions,
    :export_dependencies,
    :export_repositories,
    :export_tags,
    :export_repository_dependencies
  ]

  desc 'Export projects open data csv'
  task export_projects: :environment do
    csv_file = File.open("data/projects-#{EXPORT_VERSION}-#{EXPORT_DATE}.csv",'w')
    csv_file = CSV.new(csv_file)
    csv_file << [
      'Platform',
      'Name',
      'Created Timestamp',
      'Updated Timestamp',
      'Description',
      'Keywords',
      'Homepage URL',
      'Licenses',
      'Repository URL',
      'Versions Count',
      'SourceRank',
      'Latest Release Publish Timestamp',
      'Latest Release Number',
      'Package Manager ID',
      'Dependent Projects Count',
      'Language',
      'Status',
      'Last synced Timestamp',
      'Dependent Repositories Count'
    ]

    Project.not_removed.includes(:repository).find_each do |project|
      csv_file << [
        project.platform,
        project.name,
        project.created_at,
        project.updated_at,
        project.description.try(:tr, "\r\n",' '),
        project.keywords_array.join(','),
        project.homepage.try(:strip),
        project.normalized_licenses.join(','),
        project.repository_url.try(:strip),
        project.versions_count,
        project.rank,
        project.latest_release_published_at,
        project.latest_release_number,
        project.pm_id,
        project.dependents_count,
        project.language,
        project.status,
        project.last_synced_at,
        project.dependent_repos_count,
      ]
    end
  end

  desc 'Export versions open data csv'
  task export_versions: :environment do
    csv_file = File.open("data/versions-#{EXPORT_VERSION}-#{EXPORT_DATE}.csv",'w')
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
          version.number.try(:tr, "\r\n",' '),
          version.published_at,
          version.created_at,
          version.updated_at
        ]
      end
    end
  end

  desc 'Export dependencies open data csv'
  task export_dependencies: :environment do
    csv_file = File.open("data/dependencies-#{EXPORT_VERSION}-#{EXPORT_DATE}.csv",'w')
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
            dependency.project_name.try(:tr, "\r\n",''),
            dependency.platform.try(:tr, "\r\n",''),
            dependency.kind.try(:tr, "\r\n",''),
            dependency.optional.try(:tr, "\r\n",''),
            dependency.requirements.try(:tr, "\r\n",'')
          ]
        end
      end
    end
  end

  desc 'Export repositories open data csv'
  task export_repositories: :environment do
    csv_file = File.open("data/repositories-#{EXPORT_VERSION}-#{EXPORT_DATE}.csv",'w')
    csv_file = CSV.new(csv_file)
    csv_file << [
      'Host Type',
      'Name with Owner',
      'Description',
      'Fork?',
      'Created Timestamp',
      'Updated Timestamp',
      'Last pushed Timestamp',
      'Homepage URL',
      'Size',
      'Stars Count',
      'Language',
      'Issues enabled?',
      'Wiki enabled?',
      'Pages enabled?',
      'Forks Count',
      'Mirror URL',
      'Open Issues Count',
      'Default branch',
      'Watchers Count',
      'UUID',
      'Fork Source Name with Owner',
      'License',
      'Contributors Count',
      'Readme filename',
      'Changelog filename',
      'Contributing guidelines filename',
      'License filename',
      'Code of Conduct filename',
      'Security Threat Model filename',
      'Security Audit filename',
      'Status',
      'Last Synced Timestamp',
      'SourceRank',
      'Display Name',
      'SCM type',
      'Pull requests enabled?',
      'Logo URL',
      'Keywords'
    ]

    Repository.open_source.not_removed.find_each do |repo|
      csv_file << [
        repo.host_type,
        repo.full_name,
        repo.description.try(:tr, "\r\n",' '),
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
        repo.name,
        repo.scm,
        repo.pull_requests_enabled,
        repo.logo_url,
        repo.keywords.join(','),
      ]
    end
  end

  desc 'Export tags open data csv'
  task export_tags: :environment do
    csv_file = File.open("data/tags-#{EXPORT_VERSION}-#{EXPORT_DATE}.csv",'w')
    csv_file = CSV.new(csv_file)
    csv_file << [
      'Host Type',
      'Repository Name with Owner',
      'Tag Name',
      'Tag git sha',
      'Tag Published Timestamp',
      'Tag Created Timestamp',
      'Tag Updated Timestamp'
    ]

    Repository.open_source.not_removed.includes(:tags).find_each do |repo|
      repo.tags.each do |tag|
        csv_file << [
          repo.host_type,
          repo.full_name,
          tag.name.try(:tr, "\r\n",' '),
          tag.sha,
          tag.published_at,
          tag.created_at,
          tag.updated_at
        ]
      end
    end
  end

  desc 'Export repository dependencies open data csv'
  task export_repository_dependencies: :environment do
    csv_file = File.open("data/repository_dependencies-#{EXPORT_VERSION}-#{EXPORT_DATE}.csv",'w')
    csv_file = CSV.new(csv_file)
    csv_file << [
      'Host Type',
      'Repository Name with Owner',
      'Manifest Platform',
      'Manifest Filepath',
      'Git branch',
      'Manifest kind',
      'Optional?',
      'Dependency Project Name',
      'Dependency Requirements',
      'Dependency Kind'
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
            repository_dependency.project_name.try(:tr, "\r\n",' '),
            repository_dependency.requirements.try(:tr, "\r\n",' '),
            repository_dependency.kind.try(:tr, "\r\n",' ')
          ]
        end
      end
    end
  end
end
