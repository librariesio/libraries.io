require 'rails_helper'

describe Repositories::Pub do
  it 'has formatted name of "Pub"' do
    expect(Repositories::Pub.formatted_name).to eq('Pub')
  end
end
