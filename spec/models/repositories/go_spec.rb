require 'rails_helper'

describe Repositories::Go do
  it 'has formatted name of "Go"' do
    expect(Repositories::Go.formatted_name).to eq('Go')
  end
end
