require 'rails_helper'

describe Repositories::Elm do
  it 'has formatted name of "Elm"' do
    expect(Repositories::Elm.formatted_name).to eq('Elm')
  end
end
