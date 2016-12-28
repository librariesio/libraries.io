require 'rails_helper'

describe PackageManager::Jam do
  it 'has formatted name of "Jam"' do
    expect(PackageManager::Jam.formatted_name).to eq('Jam')
  end
end
