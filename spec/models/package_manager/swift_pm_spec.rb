# frozen_string_literal: true
require 'rails_helper'

describe PackageManager::SwiftPM do
  it 'has formatted name of "SwiftPM"' do
    expect(PackageManager::SwiftPM.formatted_name).to eq('SwiftPM')
  end
end
