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

  def url
    path = pull_request ? 'pull' : 'issues'
    "#{repository.url}/#{path}/#{number}"
  end

  def github_client(token = nil)
    AuthToken.fallback_client(token)
  end

  def sync(token = nil)
    IssueWorker.perform_async(repository.full_name, number, token)
  end

  def self.create_from_hash(repo, issue_hash)
    issue_hash = issue_hash.to_hash
    i = repo.issues.find_or_create_by(github_id: issue_hash[:id])
    i.repository_user_id = issue_hash[:user][:id]
    i.repository_id = repo.id
    i.labels = issue_hash[:labels].map{|l| l[:name] }
    i.pull_request = issue_hash[:pull_request].present?
    i.comments_count = issue_hash[:comments]
    i.assign_attributes issue_hash.slice(*Issue::API_FIELDS)
    if i.changed?
      i.last_synced_at = Time.now
      i.save!
    end
    i
  end

  def contributions_count
    repository.try(:contributions_count) || 0
  end

  def language
    repository.try(:language)
  end

  def license
    repository.try(:license)
  end

  def stars
    repository.try(:stargazers_count) || 0
  end

  def rank
    repository.try(:rank) || 0
  end

  def self.update_from_github(name_with_owner, issue_number, token = nil)
    token ||= AuthToken.token
    repo = Repository.host('GitHub').find_by_full_name(name_with_owner) || RepositoryHost::Github.create(name_with_owner, token)
    return unless repo
    issue_hash = AuthToken.fallback_client(token).issue(repo.full_name, issue_number)
    Issue.create_from_hash(repo, issue_hash)
  rescue Octokit::NotFound, Octokit::ClientError
    nil
  end
end
