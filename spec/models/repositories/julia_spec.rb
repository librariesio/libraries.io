require 'rails_helper'

describe Repositories::Julia do
  it 'has formatted name of "Julia"' do
    expect(Repositories::Julia.formatted_name).to eq('Julia')
  end
end
