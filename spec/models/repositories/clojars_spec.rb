require 'rails_helper'

describe Repositories::Clojars do
  it 'has formatted name of "Clojars"' do
    expect(Repositories::Clojars.formatted_name).to eq('Clojars')
  end
end
