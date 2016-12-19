require 'rails_helper'

describe Repositories::Pub, :vcr do
  it 'has formatted name of "Pub"' do
    expect(described_class.formatted_name).to eq('Pub')
  end

  describe '#package_link' do
    let(:project) { create(:project, name: 'foo', platform: described_class.name) }

    it 'returns a link to project website' do
      expect(described_class.package_link(project)).to eq("https://pub.dartlang.org/packages/foo")
    end

    it 'ignores version' do
      expect(described_class.package_link(project, '2.0.0')).to eq("https://pub.dartlang.org/packages/foo")
    end
  end
end
