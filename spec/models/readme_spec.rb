require 'rails_helper'

describe Readme, type: :model do
  it { should belong_to(:repository) }

  it { should validate_presence_of(:html_body) }
  it { should validate_presence_of(:repository) }
end
