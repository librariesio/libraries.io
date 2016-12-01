class GithubIssue < ApplicationRecord
  include IssueSearch

  belongs_to :github_repository
  belongs_to :github_user, primary_key: :github_id

  API_FIELDS = [:number, :state, :title, :body, :locked, :closed_at, :created_at, :updated_at]
  FIRST_PR_LABELS = ['good first bug', 'good first contribution', 'good-first-bug',
                     'first-timers-only', 'good first issue', 'good first task',
                     'easy first bug', 'your first pr', 'firstbug', 'good-first-pr',
                     '[Type] Good First Bug', 'good first patch', 'first bug',
                     'good first step', 'good-first-issue', 'IdealFirstBug',
                     'first contribution', 'first timers only', 'your-first-pr',
                     'starter', 'beginner', 'easy', 'E-easy']

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
  scope :indexable, -> { actionable.includes(:github_repository) }

  def url
    path = pull_request ? 'pull' : 'issues'
    "#{github_repository.url}/#{path}/#{number}"
  end

  def github_client(token = nil)
    AuthToken.fallback_client(token)
  end

  def sync(token = nil)
    GithubIssueWorker.perform_async(github_repository.full_name, number, token)
  end

  def self.create_from_hash(repo, issue_hash)
    issue_hash = issue_hash.to_hash
    i = repo.github_issues.find_or_create_by(github_id: issue_hash[:id])
    i.github_user_id = issue_hash[:user][:id]
    i.github_repository_id = repo.id
    i.labels = issue_hash[:labels].map{|l| l[:name] }
    i.pull_request = issue_hash[:pull_request].present?
    i.comments_count = issue_hash[:comments]
    i.assign_attributes issue_hash.slice(*GithubIssue::API_FIELDS)
    i.last_synced_at = Time.now
    i.save! if i.changed?
    i
  end

  def contributions_count
    github_repository.try(:github_contributions_count) || 0
  end

  def language
    github_repository.try(:language)
  end

  def license
    github_repository.try(:license)
  end

  def stars
    github_repository.try(:stargazers_count) || 0
  end
end
