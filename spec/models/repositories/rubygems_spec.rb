require 'rails_helper'

describe Repositories::Rubygems do
  it 'has formatted name of "Rubygems"' do
    expect(Repositories::Rubygems.formatted_name).to eq('Rubygems')
  end
end
