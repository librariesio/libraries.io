require 'rails_helper'

describe Manifest do
  it { should belong_to(:github_repository) }
  it { should have_many(:repository_dependencies) }
end
