require 'rails_helper'

describe Repositories::Maven do
  it 'has formatted name of "Maven"' do
    expect(Repositories::Maven.formatted_name).to eq('Maven')
  end
end
