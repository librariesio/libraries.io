require 'rails_helper'

describe Version do
  it { should belong_to(:project) }
  it { should have_many(:dependencies) }

  it { should validate_presence_of(:project_id) }
  it { should validate_presence_of(:number) }
  it { should validate_uniqueness_of(:number).scoped_to(:project_id) }
end
