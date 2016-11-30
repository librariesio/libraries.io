require 'rails_helper'

describe Repositories::Inqlude do
  it 'has formatted name of "Inqlude"' do
    expect(Repositories::Inqlude.formatted_name).to eq('Inqlude')
  end
end
