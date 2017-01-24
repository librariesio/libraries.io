require 'rails_helper'

describe Manifest, type: :model do
  it { should belong_to(:repository).with_foreign_key('github_repository_id') }
  it { should have_many(:repository_dependencies) }
end
