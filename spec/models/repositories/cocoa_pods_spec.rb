require 'rails_helper'

describe Repositories::CocoaPods do
  it 'has formatted name of "CocoaPods"' do
    expect(Repositories::CocoaPods.formatted_name).to eq('CocoaPods')
  end
end
