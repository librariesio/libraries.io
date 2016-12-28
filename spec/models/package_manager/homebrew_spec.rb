require 'rails_helper'

describe PackageManager::Homebrew, :vcr do
  it 'has formatted name of "Homebrew"' do
    expect(described_class.formatted_name).to eq('Homebrew')
  end

  describe '#package_link' do
    let(:project) { create(:project, name: 'foo', platform: described_class.name) }

    it 'returns a link to project website' do
      expect(described_class.package_link(project)).to eq("http://brewformulas.org/foo")
    end

    it 'ignores version' do
      expect(described_class.package_link(project, '2.0.0')).to eq("http://brewformulas.org/foo")
    end
  end
end
