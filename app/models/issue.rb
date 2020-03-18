# frozen_string_literal: true

class Issue < ApplicationRecord
  include IssueSearch

  belongs_to :repository
  belongs_to :repository_user

  API_FIELDS = %i[number state title body locked closed_at created_at updated_at].freeze
  FIRST_PR_LABELS = ["good first bug", "good first contribution", "good-first-bug",
                     "first-timers-only", "good first issue", "good first task",
                     "easy first bug", "your first pr", "firstbug", "good-first-pr",
                     "[Type] Good First Bug", "good first patch", "first bug",
                     "good first step", "good-first-issue", "IdealFirstBug",
                     "first contribution", "first timers only", "your-first-pr",
                     "starter", "beginner", "easy", "E-easy"].freeze

  # eager load this module to avoid clashing with Gitlab gem in development
  RepositoryIssue::Gitlab

  scope :open, -> { where(state: "open") }
  scope :closed, -> { where(state: "closed") }
  scope :issue, -> { where(pull_request: false) }
  scope :pull_request, -> { where(pull_request: true) }
  scope :locked, -> { where(locked: true) }
  scope :unlocked, -> { where(locked: false) }
  scope :actionable, -> { open.issue.unlocked }
  scope :labeled, ->(label) { where("issues.labels @> ?", Array(label).to_postgres_array(true)) }
  scope :help_wanted, -> { labeled("help wanted") }
  scope :first_pull_request, -> { where("issues.labels && ?", Array(FIRST_PR_LABELS).to_postgres_array(true)) }
  scope :indexable, -> { actionable.includes(:repository) }

  scope :host, ->(host_type) { where("lower(issues.host_type) = ?", host_type.try(:downcase)) }

  delegate :language, :license, to: :repository
  delegate :url, :label_url, to: :repository_issue

  def issue_type
    pull_request ? "pull_request" : "issue"
  end

  def sync(token = nil)
    RepositoryIssue::Base.update(host_type, repository.full_name, number, issue_type, token)
  end

  def async_sync(token = nil)
    IssueWorker.perform_async(host_type, repository.full_name, number, issue_type, token)
  end

  def contributions_count
    repository.try(:contributions_count) || 0
  end

  def stars
    repository.try(:stargazers_count) || 0
  end

  def rank
    repository.try(:rank) || 0
  end

  def github_id
    uuid # legacy alias
  end

  def repository_issue
    @repository_issue ||= RepositoryIssue.const_get(host_type.capitalize).new(self)
  end
end
