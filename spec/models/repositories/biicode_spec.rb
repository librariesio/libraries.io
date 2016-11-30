require 'rails_helper'

describe Repositories::Biicode do
  it 'has formatted name of "biicode"' do
    expect(Repositories::Biicode.formatted_name).to eq('biicode')
  end
end
