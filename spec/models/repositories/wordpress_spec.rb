require 'rails_helper'

describe Repositories::Wordpress do
  it 'has formatted name of "WordPress"' do
    expect(Repositories::Wordpress.formatted_name).to eq('WordPress')
  end
end
