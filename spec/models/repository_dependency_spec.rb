# frozen_string_literal: true
require 'rails_helper'

describe RepositoryDependency, type: :model do
  it { should belong_to(:manifest) }
  it { should belong_to(:project) }
end
