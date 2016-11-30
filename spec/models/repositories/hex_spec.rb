require 'rails_helper'

describe Repositories::Hex do
  it 'has formatted name of "Hex"' do
    expect(Repositories::Hex.formatted_name).to eq('Hex')
  end
end
