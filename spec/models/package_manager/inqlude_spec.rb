require 'rails_helper'

describe PackageManager::Inqlude, :vcr do
  it 'has formatted name of "Inqlude"' do
    expect(described_class.formatted_name).to eq('Inqlude')
  end

  describe '#package_link' do
    let(:project) { create(:project, name: 'foo', platform: described_class.name) }

    it 'returns a link to project website' do
      expect(described_class.package_link(project)).to eq("https://inqlude.org/libraries/foo.html")
    end

    it 'ignores version' do
      expect(described_class.package_link(project, '2.0.0')).to eq("https://inqlude.org/libraries/foo.html")
    end
  end
end
