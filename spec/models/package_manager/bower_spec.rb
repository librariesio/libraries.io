require 'rails_helper'

describe PackageManager::Bower do
  it 'has formatted name of "Bower"' do
    expect(PackageManager::Bower.formatted_name).to eq('Bower')
  end
end
