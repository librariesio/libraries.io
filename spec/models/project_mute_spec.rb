# frozen_string_literal: true

require "rails_helper"

describe ProjectMute, type: :model do
  subject { FactoryBot.build(:project_mute) }

  it { should belong_to(:user) }
  it { should belong_to(:project) }

  it { should validate_presence_of(:project_id) }
  it { should validate_presence_of(:user_id) }
  it { should validate_uniqueness_of(:project_id).scoped_to(:user_id) }
end
