require 'rails_helper'

describe ApiKey do
  it { should belong_to(:user) }
end
