require 'rails_helper'

describe Repositories::Haxelib do
  it 'has formatted name of "Haxelib"' do
    expect(Repositories::Haxelib.formatted_name).to eq('Haxelib')
  end
end
