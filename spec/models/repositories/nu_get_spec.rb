require 'rails_helper'

describe Repositories::NuGet do
  it 'has formatted name of "NuGet"' do
    expect(Repositories::NuGet.formatted_name).to eq('NuGet')
  end
end
