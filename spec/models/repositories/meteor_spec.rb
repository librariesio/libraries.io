require 'rails_helper'

describe Repositories::Meteor do
  it 'has formatted name of "Meteor"' do
    expect(Repositories::Meteor.formatted_name).to eq('Meteor')
  end
end
