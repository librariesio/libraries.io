require 'rails_helper'

describe Repositories::Alcatraz do
  it 'has formatted name of "Alcatraz"' do
    expect(Repositories::Alcatraz.formatted_name).to eq('Alcatraz')
  end
end
