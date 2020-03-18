# frozen_string_literal: true

class RepositorySerializer < ActiveModel::Serializer
  attributes :full_name, :description, :fork, :created_at, :updated_at,
             :pushed_at, :homepage, :size, :stargazers_count, :language,
             :has_issues, :has_wiki, :has_pages, :forks_count, :mirror_url,
             :open_issues_count, :default_branch, :subscribers_count, :uuid,
             :source_name, :license, :private, :contributions_count, :has_readme,
             :has_changelog, :has_contributing, :has_license, :has_coc,
             :has_threat_model, :has_audit, :status, :last_synced_at, :rank,
             :host_type, :host_domain, :name, :scm, :fork_policy, :github_id,
             :pull_requests_enabled, :logo_url, :github_contributions_count, :keywords
end
