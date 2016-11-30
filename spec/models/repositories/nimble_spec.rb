require 'rails_helper'

describe Repositories::Nimble do
  it 'has formatted name of "Nimble"' do
    expect(Repositories::Nimble.formatted_name).to eq('Nimble')
  end
end
