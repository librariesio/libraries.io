require 'rails_helper'

describe WebHook, type: :model do
  it { should belong_to(:repository).with_foreign_key('github_repository_id') }
  it { should belong_to(:user) }
  it { should validate_presence_of(:url) }
end
