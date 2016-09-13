class AccountSubscriptionsController < ApplicationController
  before_action :ensure_logged_in, :except => :plans

  include Payola::StatusBehavior

  def plans
    default_interval = current_user.try(:current_plan).try(:interval) || 'month'
    @interval = params[:interval] == 'year' ? 'year' : default_interval
    @plans = SubscriptionPlan.visible.interval(@interval)
  end

  def new
    @plan = SubscriptionPlan.first
  end

  def create
    # do any required setup here, including finding or creating the owner object
    owner = current_user # this is just an example for Devise

    # set your plan in the params hash
    params[:plan] = SubscriptionPlan.find_by(id: params[:plan_id])

    # call Payola::CreateSubscription
    subscription = Payola::CreateSubscription.call(params, owner)

    # Render the status json that Payola's javascript expects
    render_payola_status(subscription)
  end

end
