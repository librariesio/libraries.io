require 'rails_helper'

describe Repositories::SwiftPM do
  it 'has formatted name of "SwiftPM"' do
    expect(Repositories::SwiftPM.formatted_name).to eq('SwiftPM')
  end
end
