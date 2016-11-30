require 'rails_helper'

describe Repositories::Pypi do
  it 'has formatted name of "PyPI"' do
    expect(Repositories::Pypi.formatted_name).to eq('PyPI')
  end
end
