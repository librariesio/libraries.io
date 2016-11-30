require 'rails_helper'

describe Repositories::NPM do
  it 'has formatted name of "npm"' do
    expect(Repositories::NPM.formatted_name).to eq('npm')
  end
end
