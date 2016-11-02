require 'rails_helper'

describe ProjectMute do
  subject { FactoryGirl.build(:project_mute) }

  it { should belong_to(:user) }
  it { should belong_to(:project) }

  it { should validate_presence_of(:project_id) }
  it { should validate_presence_of(:user_id) }
  it { should validate_uniqueness_of(:project_id).scoped_to(:user_id) }
end
