class SubscriptionPlan < ApplicationRecord
  include Payola::Plan

  scope :visible, -> { where(hidden: false) }
  scope :interval, -> (interval){ where(interval: interval).order('amount ASC') }

  PLANS = [
    {
      amount: 4999,
      interval: 'month',
      stripe_id: '1',
      name: 'Bronze Monthly',
      repo_count: 2
    },
    {
      amount: 12999,
      interval: 'month',
      stripe_id: '2',
      name: 'Silver Monthly',
      repo_count: 6
    },
    {
      amount: 24999,
      interval: 'month',
      stripe_id: '3',
      name: 'Gold Monthly',
      repo_count: 15
    },
    {
      amount: 54999,
      interval: 'year',
      stripe_id: '4',
      name: 'Bronze Yearly',
      repo_count: 2
    },
    {
      amount: 142999,
      interval: 'year',
      stripe_id: '5',
      name: 'Silver Yearly',
      repo_count: 6
    },
    {
      amount: 274989,
      interval: 'year',
      stripe_id: '6',
      name: 'Gold Yearly',
      repo_count: 15
    },
    {
      amount: 2500,
      interval: 'month',
      stripe_id: '7',
      name: 'Startup Monthly',
      repo_count: 1
    },
    {
      amount: 27500,
      interval: 'year',
      stripe_id: '8',
      name: 'Startup Yearly',
      repo_count: 1
    },
    {
      amount: 0,
      interval: 'year',
      stripe_id: '9',
      name: 'Educational',
      repo_count: 15,
      hidden: true
    }
  ]

  def self.setup_plans
    PLANS.each do |plan|
      self.find_or_create_by(plan)
    end
  end

  def to_s
    name
  end

  def short_name
    name.gsub(/yearly|monthly/i, '').strip
  end

  def repo_count
    plan_hash[:repo_count]
  end

  def plan_hash
    PLANS.find{|p| p[:stripe_id] == self.stripe_id }
  end

  def redirect_path(subscription)
    '/repositories'
  end
end
