require 'rails_helper'

describe PackageManager::Sublime, :vcr do
  it 'has formatted name of "Sublime"' do
    expect(described_class.formatted_name).to eq('Sublime')
  end

  describe '#package_link' do
    let(:project) { create(:project, name: 'foo', platform: described_class.name) }

    it 'returns a link to project website' do
      expect(described_class.package_link(project)).to eq("https://packagecontrol.io/packages/foo")
    end

    it 'ignores version' do
      expect(described_class.package_link(project, '2.0.0')).to eq("https://packagecontrol.io/packages/foo")
    end
  end
end
