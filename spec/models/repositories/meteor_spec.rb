require 'rails_helper'

describe Repositories::Meteor, :vcr do
  it 'has formatted name of "Meteor"' do
    expect(described_class.formatted_name).to eq('Meteor')
  end

  describe '#package_link' do
    let(:project) { create(:project, name: 'foo:bar', platform: described_class.name) }

    it 'returns a link to project website' do
      expect(described_class.package_link(project)).to eq("https://atmospherejs.com/foo/bar")
    end

    it 'ignores version' do
      expect(described_class.package_link(project, '2.0.0')).to eq("https://atmospherejs.com/foo/bar")
    end
  end
end
