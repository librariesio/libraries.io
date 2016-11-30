require 'rails_helper'

describe Repositories::Bower do
  it 'has formatted name of "Bower"' do
    expect(Repositories::Bower.formatted_name).to eq('Bower')
  end
end
