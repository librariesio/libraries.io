# frozen_string_literal: true
require 'rails_helper'

describe PackageManager::Carthage do
  it 'has formatted name of "Carthage"' do
    expect(PackageManager::Carthage.formatted_name).to eq('Carthage')
  end
end
