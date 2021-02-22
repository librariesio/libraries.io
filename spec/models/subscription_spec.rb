# frozen_string_literal: true
require 'rails_helper'

describe Subscription, type: :model do
  it { should belong_to(:project) }
  it { should belong_to(:user) }
  it { should belong_to(:repository_subscription) }

  it { should have_one(:repository) }

  it { should validate_presence_of(:project) }
end
