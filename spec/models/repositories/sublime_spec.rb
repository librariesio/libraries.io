require 'rails_helper'

describe Repositories::Sublime do
  it 'has formatted name of "Sublime"' do
    expect(Repositories::Sublime.formatted_name).to eq('Sublime')
  end
end
