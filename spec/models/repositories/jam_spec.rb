require 'rails_helper'

describe Repositories::Jam do
  it 'has formatted name of "Jam"' do
    expect(Repositories::Jam.formatted_name).to eq('Jam')
  end
end
