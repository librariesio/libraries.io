# frozen_string_literal: true
require 'rails_helper'

describe RepositoryPermission, type: :model do
  it { should belong_to(:repository) }
  it { should belong_to(:user) }

  it { should validate_uniqueness_of(:repository_id).scoped_to(:user_id) }
end
