# frozen_string_literal: true
require 'rails_helper'

describe Contribution, type: :model do
  it { should belong_to(:repository_user) }
  it { should belong_to(:repository) }
end
