require 'rails_helper'

describe PackageManager::Alcatraz do
  it 'has formatted name of "Alcatraz"' do
    expect(PackageManager::Alcatraz.formatted_name).to eq('Alcatraz')
  end
end
