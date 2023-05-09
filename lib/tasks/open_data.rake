# frozen_string_literal: true

require "csv"

EXPORT_VERSION = "1.6.0"
EXPORT_DATE = "2020-01-12"

namespace :open_data do
  desc "Export all open data csvs"
  task export: %i[
    export_projects
    export_versions
    export_dependencies
    export_repositories
    export_tags
    export_repository_dependencies
    export_projects_with_repository_fields
  ]

  desc "Export projects open data csv"
  task export_projects: :environment do
    csv_file = File.open("data/projects-#{EXPORT_VERSION}-#{EXPORT_DATE}.csv", "w")
    csv_file = CSV.new(csv_file)
    csv_file << [
      "ID",
      "Platform",
      "Name",
      "Created Timestamp",
      "Updated Timestamp",
      "Description",
      "Keywords",
      "Homepage URL",
      "Licenses",
      "Repository URL",
      "Versions Count",
      "SourceRank",
      "Latest Release Publish Timestamp",
      "Latest Release Number",
      "Package Manager ID",
      "Dependent Projects Count",
      "Language",
      "Status",
      "Last synced Timestamp",
      "Dependent Repositories Count",
      "Repository ID",
    ]

    Project.not_removed.includes(:repository).find_each do |project|
      csv_file << [
        project.id,
        project.platform,
        project.name,
        project.created_at,
        project.updated_at,
        project.description.try(:tr, "\r\n", " "),
        project.keywords_array.join(",").try(:tr, "\r\n", " "),
        project.homepage.try(:tr, "\r\n", " ").try(:strip),
        project.normalized_licenses.join(","),
        project.repository_url.try(:tr, "\r\n", " ").try(:strip),
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
        project.repository_id,
      ]
    end
  end

  desc "Export projects with repository fields open data csv"
  task export_projects_with_repository_fields: :environment do
    csv_file = File.open("data/projects_with_repository_fields-#{EXPORT_VERSION}-#{EXPORT_DATE}.csv", "w")
    csv_file = CSV.new(csv_file)
    csv_file << [
      "ID",
      "Platform",
      "Name",
      "Created Timestamp",
      "Updated Timestamp",
      "Description",
      "Keywords",
      "Homepage URL",
      "Licenses",
      "Repository URL",
      "Versions Count",
      "SourceRank",
      "Latest Release Publish Timestamp",
      "Latest Release Number",
      "Package Manager ID",
      "Dependent Projects Count",
      "Language",
      "Status",
      "Last synced Timestamp",
      "Dependent Repositories Count",
      "Repository ID",
      "Repository Host Type",
      "Repository Name with Owner",
      "Repository Description",
      "Repository Fork?",
      "Repository Created Timestamp",
      "Repository Updated Timestamp",
      "Repository Last pushed Timestamp",
      "Repository Homepage URL",
      "Repository Size",
      "Repository Stars Count",
      "Repository Language",
      "Repository Issues enabled?",
      "Repository Wiki enabled?",
      "Repository Pages enabled?",
      "Repository Forks Count",
      "Repository Mirror URL",
      "Repository Open Issues Count",
      "Repository Default branch",
      "Repository Watchers Count",
      "Repository UUID",
      "Repository Fork Source Name with Owner",
      "Repository License",
      "Repository Contributors Count",
      "Repository Readme filename",
      "Repository Changelog filename",
      "Repository Contributing guidelines filename",
      "Repository License filename",
      "Repository Code of Conduct filename",
      "Repository Security Threat Model filename",
      "Repository Security Audit filename",
      "Repository Status",
      "Repository Last Synced Timestamp",
      "Repository SourceRank",
      "Repository Display Name",
      "Repository SCM type",
      "Repository Pull requests enabled?",
      "Repository Logo URL",
      "Repository Keywords",
    ]

    Project.not_removed.includes(:repository).find_each do |project|
      repo = project.repository
      csv_file << [
        project.id,
        project.platform,
        project.name,
        project.created_at,
        project.updated_at,
        project.description.try(:tr, "\r\n", " "),
        project.keywords_array.join(",").try(:tr, "\r\n", " "),
        project.homepage.try(:tr, "\r\n", " ").try(:strip),
        project.normalized_licenses.join(","),
        project.repository_url.try(:tr, "\r\n", " ").try(:strip),
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
        project.repository_id,
        repo.try(:host_type),
        repo.try(:full_name),
        repo.try(:description).try(:tr, "\r\n", " "),
        repo.try(:fork),
        repo.try(:created_at),
        repo.try(:updated_at),
        repo.try(:pushed_at),
        repo.try(:homepage),
        repo.try(:size),
        repo.try(:stargazers_count),
        repo.try(:language),
        repo.try(:has_issues),
        repo.try(:has_wiki),
        repo.try(:has_pages),
        repo.try(:forks_count),
        repo.try(:mirror_url),
        repo.try(:open_issues_count),
        repo.try(:default_branch),
        repo.try(:subscribers_count),
        repo.try(:uuid),
        repo.try(:source_name),
        repo.try(:license),
        repo.try(:contributions_count),
        repo.try(:has_readme).presence || "",
        repo.try(:has_changelog).presence || "",
        repo.try(:has_contributing).presence || "",
        repo.try(:has_license).presence || "",
        repo.try(:has_coc).presence || "",
        repo.try(:has_threat_model).presence || "",
        repo.try(:has_audit).presence || "",
        repo.try(:status),
        repo.try(:last_synced_at),
        repo.try(:rank),
        repo.try(:host_type),
        repo.try(:name),
        repo.try(:scm),
        repo.try(:pull_requests_enabled),
        repo.try(:logo_url),
        repo.try(:keywords).try(:join, ","),
      ]
    end
  end

  desc "Export versions open data csv"
  task export_versions: :environment do
    csv_file = File.open("data/versions-#{EXPORT_VERSION}-#{EXPORT_DATE}.csv", "w")
    csv_file = CSV.new(csv_file)
    csv_file << [
      "ID",
      "Platform",
      "Project Name",
      "Project ID",
      "Number",
      "Published Timestamp",
      "Created Timestamp",
      "Updated Timestamp",
    ]

    Project.not_removed.includes(:versions).find_each do |project|
      project.versions.each do |version|
        csv_file << [
          version.id,
          project.platform,
          project.name,
          project.id,
          version.number.try(:tr, "\r\n", " "),
          version.published_at,
          version.created_at,
          version.updated_at,
        ]
      end
    end
  end

  desc "Export dependencies open data csv"
  task export_dependencies: :environment do
    csv_file = File.open("data/dependencies-#{EXPORT_VERSION}-#{EXPORT_DATE}.csv", "w")
    csv_file = CSV.new(csv_file)
    csv_file << [
      "ID",
      "Platform",
      "Project Name",
      "Project ID",
      "Version Number",
      "Version ID",
      "Dependency Name",
      "Dependency Platform",
      "Dependency Kind",
      "Optional Dependency",
      "Dependency Requirements",
      "Dependency Project ID",
    ]

    Project.not_removed.includes(versions: :dependencies).find_each do |project|
      project.versions.each do |version|
        version.dependencies.each do |dependency|
          csv_file << [
            dependency.id,
            project.platform,
            project.name,
            project.id,
            version.number,
            version.id,
            dependency.project_name.try(:tr, "\r\n", ""),
            dependency.platform.try(:tr, "\r\n", ""),
            dependency.kind.try(:tr, "\r\n", ""),
            dependency.optional,
            dependency.requirements.try(:tr, "\r\n", ""),
            dependency.project_id,
          ]
        end
      end
    end
  end

  desc "Export repositories open data csv"
  task export_repositories: :environment do
    csv_file = File.open("data/repositories-#{EXPORT_VERSION}-#{EXPORT_DATE}.csv", "w")
    csv_file = CSV.new(csv_file)
    csv_file << [
      "ID",
      "Host Type",
      "Name with Owner",
      "Description",
      "Fork",
      "Created Timestamp",
      "Updated Timestamp",
      "Last pushed Timestamp",
      "Homepage URL",
      "Size",
      "Stars Count",
      "Language",
      "Issues enabled",
      "Wiki enabled",
      "Pages enabled",
      "Forks Count",
      "Mirror URL",
      "Open Issues Count",
      "Default branch",
      "Watchers Count",
      "UUID",
      "Fork Source Name with Owner",
      "License",
      "Contributors Count",
      "Readme filename",
      "Changelog filename",
      "Contributing guidelines filename",
      "License filename",
      "Code of Conduct filename",
      "Security Threat Model filename",
      "Security Audit filename",
      "Status",
      "Last Synced Timestamp",
      "SourceRank",
      "Display Name",
      "SCM type",
      "Pull requests enabled",
      "Logo URL",
      "Keywords",
    ]

    Repository.open_source.not_removed.find_each do |repo|
      csv_file << [
        repo.id,
        repo.host_type,
        repo.full_name,
        repo.description.try(:tr, "\r\n", " "),
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
        repo.has_readme.presence || "",
        repo.has_changelog.presence || "",
        repo.has_contributing.presence || "",
        repo.has_license.presence || "",
        repo.has_coc.presence || "",
        repo.has_threat_model.presence || "",
        repo.has_audit.presence || "",
        repo.status,
        repo.last_synced_at,
        repo.rank,
        repo.host_type,
        repo.name,
        repo.scm,
        repo.pull_requests_enabled,
        repo.logo_url,
        repo.keywords.join(","),
      ]
    end
  end

  desc "Export tags open data csv"
  task export_tags: :environment do
    csv_file = File.open("data/tags-#{EXPORT_VERSION}-#{EXPORT_DATE}.csv", "w")
    csv_file = CSV.new(csv_file)
    csv_file << [
      "ID",
      "Host Type",
      "Repository Name with Owner",
      "Repository ID",
      "Tag Name",
      "Tag git sha",
      "Tag Published Timestamp",
      "Tag Created Timestamp",
      "Tag Updated Timestamp",
    ]

    Repository.open_source.not_removed.includes(:tags).find_each do |repo|
      repo.tags.each do |tag|
        csv_file << [
          tag.id,
          repo.host_type,
          repo.full_name,
          repo.id,
          tag.name.try(:tr, "\r\n", " "),
          tag.sha,
          tag.published_at,
          tag.created_at,
          tag.updated_at,
        ]
      end
    end
  end

  desc "Export repository dependencies open data csv"
  task export_repository_dependencies: :environment do
    csv_file = File.open("data/repository_dependencies-#{EXPORT_VERSION}-#{EXPORT_DATE}.csv", "w")
    csv_file = CSV.new(csv_file)
    csv_file << [
      "ID",
      "Host Type",
      "Repository Name with Owner",
      "Repository ID",
      "Manifest Platform",
      "Manifest Filepath",
      "Git branch",
      "Manifest kind",
      "Optional",
      "Dependency Project Name",
      "Dependency Requirements",
      "Dependency Kind",
      "Dependency Project ID",
    ]

    Repository.open_source.not_removed.includes(manifests: :repository_dependencies).find_each do |repo|
      repo.manifests.each do |manifest|
        manifest.repository_dependencies.each do |repository_dependency|
          csv_file << [
            repository_dependency.id,
            repo.host_type,
            repo.full_name,
            repo.id,
            manifest.platform,
            manifest.filepath.try(:strip),
            manifest.branch,
            manifest.kind,
            repository_dependency.optional,
            repository_dependency.project_name.try(:tr, "\r\n", " "),
            repository_dependency.requirements.try(:tr, "\r\n", " "),
            repository_dependency.kind.try(:tr, "\r\n", " "),
            repository_dependency.project_id,
          ]
        end
      end
    end
  end
end
