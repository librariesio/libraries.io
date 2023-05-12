# frozen_string_literal: true

require "rails_helper"

describe RepositorySubscription, type: :model do
  it { should belong_to(:user) }
  it { should have_many(:subscriptions) }
  it { should belong_to(:repository) }
end
