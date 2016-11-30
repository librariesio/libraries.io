require 'rails_helper'

describe Repositories::CPAN do
  it 'has formatted name of "CPAN"' do
    expect(Repositories::CPAN.formatted_name).to eq('CPAN')
  end
end
