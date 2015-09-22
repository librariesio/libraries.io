class SubscriptionPlan < ActiveRecord::Base
  include Payola::Plan

  def redirect_path(subscription)
    '/'
  end
end
