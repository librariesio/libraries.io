# frozen_string_literal: true

require "rails_helper"

describe ProjectSuggestion, type: :model do
  it { should belong_to(:user) }
  it { should belong_to(:project) }

  it { should validate_presence_of(:user) }
  it { should validate_presence_of(:project) }
  it { should validate_presence_of(:notes) }
end
