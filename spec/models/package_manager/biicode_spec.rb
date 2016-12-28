require 'rails_helper'

describe PackageManager::Biicode do
  it 'has formatted name of "biicode"' do
    expect(PackageManager::Biicode.formatted_name).to eq('biicode')
  end
end
