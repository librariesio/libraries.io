require 'rails_helper'

describe RepositoryDependency do
  it { should belong_to(:manifest) }
  it { should belong_to(:project) }
end
