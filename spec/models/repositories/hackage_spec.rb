require 'rails_helper'

describe Repositories::Hackage do
  it 'has formatted name of "Hackage"' do
    expect(Repositories::Hackage.formatted_name).to eq('Hackage')
  end
end
