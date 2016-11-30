require 'rails_helper'

describe Repositories::Dub do
  it 'has formatted name of "Dub"' do
    expect(Repositories::Dub.formatted_name).to eq('Dub')
  end
end
