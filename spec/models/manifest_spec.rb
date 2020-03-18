# frozen_string_literal: true

require "rails_helper"

describe Manifest, type: :model do
  it { should belong_to(:repository) }
  it { should have_many(:repository_dependencies) }
end
