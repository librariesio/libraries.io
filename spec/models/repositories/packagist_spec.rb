require 'rails_helper'

describe Repositories::Packagist do
  it 'has formatted name of "Packagist"' do
    expect(Repositories::Packagist.formatted_name).to eq('Packagist')
  end
end
