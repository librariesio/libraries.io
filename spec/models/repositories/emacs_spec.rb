require 'rails_helper'

describe Repositories::Emacs do
  it 'has formatted name of "Emacs"' do
    expect(Repositories::Emacs.formatted_name).to eq('Emacs')
  end
end
