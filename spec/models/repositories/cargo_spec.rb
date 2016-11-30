require 'rails_helper'

describe Repositories::Cargo do
  it 'has formatted name of "Cargo"' do
    expect(Repositories::Cargo.formatted_name).to eq('Cargo')
  end
end
