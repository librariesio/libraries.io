require 'rails_helper'

describe Repositories::CRAN do
  it 'has formatted name of "CRAN"' do
    expect(Repositories::CRAN.formatted_name).to eq('CRAN')
  end
end
