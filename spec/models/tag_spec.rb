# frozen_string_literal: true

require "rails_helper"

describe Tag, type: :model do
  it { should belong_to(:repository) }

  it { should validate_presence_of(:name) }
  it { should validate_presence_of(:sha) }
  it { should validate_presence_of(:repository) }
  it { should validate_uniqueness_of(:name).scoped_to(:repository_id) }
end
