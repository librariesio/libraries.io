require 'rails_helper'

describe PackageManager::Nimble do
  it 'has formatted name of "Nimble"' do
    expect(PackageManager::Nimble.formatted_name).to eq('Nimble')
  end
end
