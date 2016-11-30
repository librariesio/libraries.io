require 'rails_helper'

describe Repositories::Carthage do
  it 'has formatted name of "Carthage"' do
    expect(Repositories::Carthage.formatted_name).to eq('Carthage')
  end
end
