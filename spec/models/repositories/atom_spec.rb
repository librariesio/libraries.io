require 'rails_helper'

describe Repositories::Atom do
  it 'has formatted name of "Atom"' do
    expect(Repositories::Atom.formatted_name).to eq('Atom')
  end
end
