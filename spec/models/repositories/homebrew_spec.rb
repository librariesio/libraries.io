require 'rails_helper'

describe Repositories::Homebrew do
  it 'has formatted name of "Homebrew"' do
    expect(Repositories::Homebrew.formatted_name).to eq('Homebrew')
  end
end
