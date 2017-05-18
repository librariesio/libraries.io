class Issue < ApplicationRecord
  include IssueSearch

  belongs_to :repository
  belongs_to :repository_user, primary_key: :uuid

  API_FIELDS = [:number, :state, :title, :body, :locked, :closed_at, :created_at, :updated_at]
  FIRST_PR_LABELS = ['good first bug', 'good first contribution', 'good-first-bug',
                     'first-timers-only', 'good first issue', 'good first task',
                     'easy first bug', 'your first pr', 'firstbug', 'good-first-pr',
                     '[Type] Good First Bug', 'good first patch', 'first bug',
                     'good first step', 'good-first-issue', 'IdealFirstBug',
                     'first contribution', 'first timers only', 'your-first-pr',
                     'starter', 'beginner', 'easy', 'E-easy']

  # eager load this module to avoid clashing with Gitlab gem in development
  RepositoryIssue::Gitlab

  scope :open, -> { where(state: 'open') }
  scope :closed, -> { where(state: 'closed') }
  scope :issue, -> { where(pull_request: false) }
  scope :pull_request, -> { where(pull_request: true) }
  scope :locked, -> { where(locked: true) }
  scope :unlocked, -> { where(locked: false) }
  scope :actionable, -> { open.issue.unlocked }
  scope :labeled, -> (label) { where.contains(labels: [label]) }
  scope :help_wanted, -> { labeled('help wanted') }
  scope :first_pull_request, -> { where.overlap(labels: FIRST_PR_LABELS) }
  scope :indexable, -> { actionable.includes(:repository) }

  scope :host, lambda{ |host_type| where('lower(issues.host_type) = ?', host_type.try(:downcase)) }

  delegate :language, :license, to: :repository
  delegate :url, :label_url, to: :repository_issue

  def sync(token = nil)
    IssueWorker.perform_async(host_type, repository.full_name, number, token)
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
