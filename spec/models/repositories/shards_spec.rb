require 'rails_helper'

describe Repositories::Shards do
  it 'has formatted name of "Shards"' do
    expect(Repositories::Shards.formatted_name).to eq('Shards')
  end
end
