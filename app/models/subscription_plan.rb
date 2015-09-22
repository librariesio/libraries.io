class SubscriptionPlan < ActiveRecord::Base
  include Payola::Plan

  scope :interval, -> (interval){ where(interval: interval).order('amount ASC') }

  PLANS = [
    {
      amount: 1999,
      interval: 'month',
      stripe_id: '1',
      name: 'Bronze Monthly'
    },
    {
      amount: 4999,
      interval: 'month',
      stripe_id: '2',
      name: 'Silver Monthly'
    },
    {
      amount: 11999,
      interval: 'month',
      stripe_id: '3',
      name: 'Gold Monthly'
    },
    {
      amount: 21989,
      interval: 'year',
      stripe_id: '4',
      name: 'Bronze Yearly'
    },
    {
      amount: 54989,
      interval: 'year',
      stripe_id: '5',
      name: 'Silver Yearly'
    },
    {
      amount: 131989,
      interval: 'year',
      stripe_id: '6',
      name: 'Gold Yearly'
    }
  ]

  def self.setup_plans
    PLANS.each do |plan|
      self.find_or_create_by(plan)
    end
  end

  def redirect_path(subscription)
    '/repositories'
  end
end
