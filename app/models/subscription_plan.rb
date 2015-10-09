class SubscriptionPlan < ActiveRecord::Base
  include Payola::Plan

  scope :interval, -> (interval){ where(interval: interval).order('amount ASC') }

  PLANS = [
    {
      amount: 1999,
      interval: 'month',
      stripe_id: '1',
      name: 'Bronze Monthly',
      repo_count: 10
    },
    {
      amount: 4999,
      interval: 'month',
      stripe_id: '2',
      name: 'Silver Monthly',
      repo_count: 50
    },
    {
      amount: 11999,
      interval: 'month',
      stripe_id: '3',
      name: 'Gold Monthly',
      repo_count: 100
    },
    {
      amount: 21989,
      interval: 'year',
      stripe_id: '4',
      name: 'Bronze Yearly',
      repo_count: 10
    },
    {
      amount: 54989,
      interval: 'year',
      stripe_id: '5',
      name: 'Silver Yearly',
      repo_count: 50
    },
    {
      amount: 131989,
      interval: 'year',
      stripe_id: '6',
      name: 'Gold Yearly',
      repo_count: 100
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
