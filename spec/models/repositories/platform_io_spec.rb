require 'rails_helper'

describe Repositories::PlatformIO do
  it 'has formatted name of "PlatformIO"' do
    expect(Repositories::PlatformIO.formatted_name).to eq('PlatformIO')
  end
end
